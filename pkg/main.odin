package main

import "core:encoding/json"
import "core:fmt"
import "core:os/os2"
import "core:strings"

// TODO implement next fetchers
// [ ] fetchFromGitHub
// [ ] fetchFromBitbucket
// [ ] fetchFromSavannah
// [ ] fetchFromSourcehut
// [ ] fetchFromGitLab
//
// URLs should follow nix-like structure like
// github:odin-lang/Odin/master
// where
// github.com -> git source
// odin-lang -> owner
// Odin -> repo
// master -> rev

FetcherType :: enum {
	fetchFromGitHub,
	fetchFromBitBucket,
	fetchFromGitLab,
	fetchFromSourceHut,
	fetchGit,
}

DerivationInfo :: struct {
	fetcher: FetcherType,
	owner:   string,
	repo:    string,
	rev:     string,
	sha256:  string,
}

FlakeOutput :: struct {
	hash:      string,
	locked:    struct {
		lastModified:           int,
		owner, repo, rev, type: string,
	},
	original:  struct {
		owner, repo, type: string,
	},
	storePath: string,
}

// Free some strings from FlakeOutput JSON result
free_flake_output :: proc(output: FlakeOutput) {
	delete(output.hash)
	delete(output.locked.owner)
	delete(output.locked.repo)
	delete(output.locked.rev)
	delete(output.locked.type)
	delete(output.original.owner)
	delete(output.original.repo)
	delete(output.original.type)
	delete(output.storePath)
}

sources_list: []string = {"github", "bitbucket", "gitlab", "sourcehut"}

get_fetcher :: proc(source: string) -> (res: FetcherType) {
	switch source {
	case "github":
		res = .fetchFromGitHub
	case "bitbucket":
		res = .fetchFromBitBucket
	case "gitlab":
		res = .fetchFromGitLab
	case "sourcehut":
		res = .fetchFromSourceHut
	case:
		res = .fetchGit
	}
	return
}

generate_sha256 :: proc(url: string, get_rev := false) -> (string, string) {
	tmp_file, _ := os2.create_temp_file("", "nix-live-derivation")
	tmp_file_info, _ := os2.fstat(tmp_file, context.allocator)
	defer os2.close(tmp_file)
	defer os2.remove(tmp_file_info.fullpath)
	defer os2.file_info_delete(tmp_file_info, context.allocator)
	process, _ := os2.process_start(
		{
			command = {"nix", "flake", "prefetch", url, "--json", "--no-pretty"},
			stdout = tmp_file,
			stdin = nil,
			stderr = os2.stderr,
		},
	)
	process_state, _ := os2.process_wait(process)
	if process_state.exit_code != 0 {
		os2.exit(1)
	}
	prefetch_info: FlakeOutput
	prefetch_data, _ := os2.read_entire_file_from_path(tmp_file_info.fullpath, context.allocator)
	defer delete(prefetch_data)
	json_unmarshal_err := json.unmarshal(prefetch_data, &prefetch_info)
	defer free_flake_output(prefetch_info)
	if get_rev {
		return strings.clone(prefetch_info.hash), strings.clone(prefetch_info.locked.rev)
	}
	return strings.clone(prefetch_info.hash), ""
}

parse_source_url :: proc(url_: string) -> DerivationInfo {
	url := strings.clone(url_)
	fetcher: FetcherType
	owner: string
	repo: string
	rev: string
	sha256: string
	source_list: [dynamic]string
	i := 0
	for len(url) != 0 || i >= len(url) - 1 {
		if len(source_list) > 4 do break
		if i > len(url) - 1 do break
		char := url[i]

		// Clone last string
		if !strings.contains_rune(url, '/') && len(url) != 0 {
			branch := strings.clone(url[:])
			append(&source_list, branch)
			break
		}

		if char == ':' {
			input := strings.clone(url[0:i])
			append(&source_list, input)
			url = strings.trim_left(url, input)
			url = strings.trim_left(url, ":")
			i = 0
		} else if char == '/' {
			input := strings.clone(url[0:i])
			append(&source_list, input)
			url = strings.trim_left(url, input)
			url = strings.trim_left(url, "/")
			i = 0
		}
		i += 1
	}
	if len(source_list) > 4 || len(source_list) < 2 {
		fmt.eprintln(
			"Provided URL for mkLive is invalid",
			"URL should follow nix-like structure, like:",
			"<gitSource>:<repo>/<owner>(/<optionalRev>)",
			sep = "\n",
		)
		os2.exit(1)
	} else {
		fetcher = get_fetcher(source_list[0])
		owner = source_list[1]
		repo = source_list[2]
		// Get main branch with git when rev is not specified
		if len(source_list) == 3 {
			rev = ""
		} else {
			rev = source_list[3]
		}
	}
	if len(rev) == 0 {
		sha256, rev = generate_sha256(url_, get_rev = true)
	} else {
		sha256, _ = generate_sha256(url_)
	}
	return {fetcher, owner, repo, rev, sha256}
}

main :: proc() {
	if len(os2.args) < 2 do os2.exit(1)
	url := os2.args[1]
	parse_info := parse_source_url(url)
	json_data, err := json.marshal(parse_info, {pretty = true, use_enum_names = true})
	if err != nil {
		fmt.eprintln("Got error creating JSON output %v", err)
		os2.exit(1)
	}
	fmt.printfln("%s", json_data)
}
