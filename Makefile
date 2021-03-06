VERSION := $(shell git describe --tags)

fetch:
	go get \
	github.com/mitchellh/gox \
	github.com/Masterminds/glide \
	github.com/modocache/gover \
	github.com/aktau/github-release && \
	glide install

clean:
	rm -f ./jabba
	rm -rf ./build

test:
	go test `go list ./... | grep -v /vendor/`

test-coverage:
	go list ./... | grep -v /vendor/ | xargs -L1 -I{} sh -c 'go test -coverprofile `basename {}`.coverprofile {}' && \
	gover && \
	go tool cover -html=gover.coverprofile -o coverage.html && \
	rm *.coverprofile

build:
	go build -ldflags "-X main.version=${VERSION}"

build-release:
	gox -verbose \
	-ldflags "-X main.version=${VERSION}" \
	-osarch="windows/amd64 linux/386 linux/amd64 darwin/amd64" \
	-output="release/{{.Dir}}-${VERSION}-{{.OS}}-{{.Arch}}" .

install: build
	JABBA_MAKE_INSTALL=true JABBA_VERSION=${VERSION} sh install.sh

publish: clean build-release
	test -n "$(GITHUB_TOKEN)" # $$GITHUB_TOKEN must be set
	github-release release --user shyiko --repo jabba --tag ${VERSION} \
	--name "${VERSION}" --description "${VERSION}" && \
	github-release upload --user shyiko --repo jabba --tag ${VERSION} \
	--name "jabba-${VERSION}-windows-amd64.exe" --file release/jabba-${VERSION}-windows-amd64.exe; \
	for qualifier in darwin-amd64 linux-386 linux-amd64 ; do \
		github-release upload --user shyiko --repo jabba --tag ${VERSION} \
		--name "jabba-${VERSION}-$$qualifier" --file release/jabba-${VERSION}-$$qualifier; \
	done
