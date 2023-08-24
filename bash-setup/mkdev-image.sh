#!/usr/bin/env bash


###### This doc is not in kube deep dive course but it give us better understanding of runtimes and how containers are run.
###### It's based on mkdev youtub channel, the dockerless containers playlist.


# Install skopeo.
apt install skopeo

###### Pull images does not exist in skopeo, instead it has some type os storage and you can copy images from and to them.
###### in below we do copy image that simply do like docker pull command.
skopeo copy docker://docker.io/alpine:latest docker-daemon:docker.io/alpine:latest

###### We see that image now is available by docker-daemon.
# root@test-logs:~# skopeo copy docker://docker.io/alpine:latest docker-daemon:docker.io/alpine:latest
# Getting image source signatures
# Copying blob 31e352740f53 [--------------------------------------] 39.3KiB / 3.2MiB
# Copying config c1aabb73d2 done
# Writing manifest to image destination
# Storing signatures
# root@test-logs:~# docker ps
# CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
# root@test-logs:~# docker images
# REPOSITORY                      TAG       IMAGE ID       CREATED         SIZE
# alpine                          latest    c1aabb73d233   6 weeks ago     7.33MB


###### The images that stored in docker-daemon is stored in `/var/lib/docker/` directory.
###### The content of image is stored in `/var/lib/docker/overlay2/` directory by default,
###### and the metadata of it is in `/var/lib/docker/image` directory.
# root@test-logs:~/archive# tree -F -L 1 /var/lib/docker/
# /var/lib/docker/
# ├── buildkit/
# ├── containers/
# ├── engine-id
# ├── image/
# ├── network/
# ├── overlay2/
# ├── plugins/
# ├── runtimes/
# ├── swarm/
# ├── tmp/
# └── volumes/


###### To see complete image as single package we can use another skopeo store type 'docker-archive'.
###### this command is like 'docker save' command.
skopeo copy docker-damon:docker.io/alpine:latest docker-archive:docker-io-alpine-latest.tar.gz
tar -xvf docker-io-alpine-latest.tar.gz
# root@test-logs:~/archive# tree .
# .
# ├── 62b0aa9725873052dc5b9bf783b6feec2b54ca348316884db21b63539f0aae1c
# │   ├── json
# │   ├── layer.tar -> ../78a822fe2a2d2c84f3de4a403188c45f623017d6a4521d23047c9fbb0801794c.tar
# │   └── VERSION
# ├── 78a822fe2a2d2c84f3de4a403188c45f623017d6a4521d23047c9fbb0801794c.tar
# ├── c1aabb73d2339c5ebaa3681de2e9d9c18d57485045a4e311d9f8004bec208d67.json
# ├── docker-io-alpine-latest.tar.gz
# ├── manifest.json
# └── repositories


###### the main file is called `manifest.json`, it defines the layers the images has and where to find configuration of this image.
cat manifest.json | jq
# [
#   {
#     "Config": "c1aabb73d2339c5ebaa3681de2e9d9c18d57485045a4e311d9f8004bec208d67.json",
#     "RepoTags": [],
#     "Layers": [
#       "78a822fe2a2d2c84f3de4a403188c45f623017d6a4521d23047c9fbb0801794c.tar"
#     ]
#   }
# ]


###### the configuration file specifies many default values used to run the container.
cat c1aabb73d2339c5ebaa3681de2e9d9c18d57485045a4e311d9f8004bec208d67.json | jq
# {
#   "architecture": "amd64",
#   "config": {
#     "Hostname": "",
#     "Domainname": "",
#     "User": "",
#     "AttachStdin": false,
#     "AttachStdout": false,
#     "AttachStderr": false,
#     "Tty": false,
#     "OpenStdin": false,
#     "StdinOnce": false,
#     "Env": [
#       "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
#     ],
#     "Cmd": [
#       "/bin/sh"
#     ],
#     "Image": "sha256:5b8658701c96acefe1cd3a21b2a80220badf9124891ad440d95a7fa500d48765",
#     "Volumes": null,
#     "WorkingDir": "",
#     "Entrypoint": null,
#     "OnBuild": null,
#     "Labels": null
#   },
#     "Tty": false,
#     "OpenStdin": false,
#     "StdinOnce": false,
#     "Env": [
#       "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
#     ],
#     "Cmd": [
#       "/bin/sh",
#       "-c",
#       "#(nop) ",
#       "CMD [\"/bin/sh\"]"
#     ],
#   },
#   "created": "2023-06-14T20:41:59.079795125Z",
#   "docker_version": "20.10.23",
#   "history": [
#     {
#       "created": "2023-06-14T20:41:58.950178204Z",
#       "created_by": "/bin/sh -c #(nop) ADD file:1da756d12551a0e3e793e02ef87432d69d4968937bd11bed0af215db19dd94cd in / "
#     },
#     {
#       "created": "2023-06-14T20:41:59.079795125Z",
#       "created_by": "/bin/sh -c #(nop)  CMD [\"/bin/sh\"]",
#       "empty_layer": true
#     }
#   ],
#   "os": "linux",
#   "rootfs": {
#     "type": "layers",
#     "diff_ids": [
#       "sha256:78a822fe2a2d2c84f3de4a403188c45f623017d6a4521d23047c9fbb0801794c"
#     ]
#   }
# }


###### Now copy image with ico storage type
skopeo copy docker://docker.io/httpd:2.4.48 oci:httpd:2.4.48
skopeo copy docker://docker.io/httpd:2.4.47 oci:httpd:2.4.47
###### all files placed in httpd direcottry.
# root@test-logs:~# tree httpd/
# httpd/
# ├── blobs
# │   └── sha256
# │       ├── 0830fa69c5f7cf4ab523ebe5ca1e7c6e5f09ed0298051e7f4819f1208effb9e0
# │       ├── 14e3dd65f04dcce813a2bfca1a76d5982fac79817dc9470a0f6abc2e51708b97
# │       ├── 2cb26220caa835d184ff393d19f3526c36751edd4060b9953b0f7b79530ba73e
# │       ├── 3138742bd84742c0eb7cadcd3caab6631baf7269046285970811ed50864059cb
# │       ├── 3b7daa309abc33ced76e64fa05ef5896b2bb3ff91d194dcec8db01ca04ac83b9
# │       ├── 40007ef9d3f1c1f23a446b555310b1f3eef8c339ee3f33f5e1b65cec6d8bc453
# │       ├── 83d3755a8d2893317ff255c45bdb1156f14496d050b5978d0c3a5ed2203c8c95
# │       ├── a330b6cecb98cd2425fd25fce36669073f593b3176b4ee14731e48c05d678cdd
# │       ├── d1589b6d8645a965434e869bd0adc4586480294e7cd62477c94357ef11c6ce10
# │       ├── df8ad48a06cbb5ccff31aa921c3d09ca77f3ef3a49fae0603bafed7aadbfc3d9
# │       ├── f0ef4325b6dbaea3e891284f673b394dc7c605d04b2ac453491ebd47fbbe0e97
# │       ├── f7ec5a41d630a33a2d1db59b95d89d93de7ae5a619a3a8571b78457e48266eba
# │       ├── fb83e95a0ade548c38ada79db0c23847f0a13f901d35d684ead4eb3a3ba11388
# │       └── fe59ad2e7efe6dce73653866d1336fe75a8b55942c2b4b29f85ef80360eafd88
# ├── index.json
# └── oci-layout


###### index.json file is points to image index manifests.
cat index.json  | jq
# {
#   "schemaVersion": 2,
#   "manifests": [
#     {
#       "mediaType": "application/vnd.oci.image.manifest.v1+json",
#       "digest": "sha256:df8ad48a06cbb5ccff31aa921c3d09ca77f3ef3a49fae0603bafed7aadbfc3d9",
#       "size": 975,
#       "annotations": {
#         "org.opencontainers.image.ref.name": "2.4.48"
#       }
#     },
#     {
#       "mediaType": "application/vnd.oci.image.manifest.v1+json",
#       "digest": "sha256:0830fa69c5f7cf4ab523ebe5ca1e7c6e5f09ed0298051e7f4819f1208effb9e0",
#       "size": 975,
#       "annotations": {
#         "org.opencontainers.image.ref.name": "2.4.47"
#       }
#     }
#   ]
# }

###### annotation is the tag we used for image.
###### simply mean that tag is not anything except annotation (metadata) to refer to something.


###### We saw that the digest is point to file that has index file of one image in the blob direcotry
###### it is index to config of the image.
###### also we see the layer of image that the first one is the base image.

cat df8ad48a06cbb5ccff31aa921c3d09ca77f3ef3a49fae0603bafed7aadbfc3d9 | jq
# {
#   "schemaVersion": 2,
#   "config": {
#     "mediaType": "application/vnd.oci.image.config.v1+json",
#     "digest": "sha256:40007ef9d3f1c1f23a446b555310b1f3eef8c339ee3f33f5e1b65cec6d8bc453",
#     "size": 7608
#   },
#   "layers": [
#     {
#       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
#       "digest": "sha256:a330b6cecb98cd2425fd25fce36669073f593b3176b4ee14731e48c05d678cdd",
#       "size": 27145844
#     },
#     {
#       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
#       "digest": "sha256:14e3dd65f04dcce813a2bfca1a76d5982fac79817dc9470a0f6abc2e51708b97",
#       "size": 174
#     },
#     {
#       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
#       "digest": "sha256:fe59ad2e7efe6dce73653866d1336fe75a8b55942c2b4b29f85ef80360eafd88",
#       "size": 2794976
#     },
#     {
#       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
#       "digest": "sha256:2cb26220caa835d184ff393d19f3526c36751edd4060b9953b0f7b79530ba73e",
#       "size": 24583386
#     },
#     {
#       "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
#       "digest": "sha256:3138742bd84742c0eb7cadcd3caab6631baf7269046285970811ed50864059cb",
#       "size": 295
#     }
#   ]
# }

###### This file have config of defaults that is needed for running container and other related thing like history of image.
cat '40007ef9d3f1c1f23a446b555310b1f3eef8c339ee3f33f5e1b65cec6d8bc453' | jq
# {
#   "created": "2021-09-03T06:56:40.263369583Z",
#   "architecture": "amd64",
#   "os": "linux",
#   "config": {
#     "ExposedPorts": {
#       "80/tcp": {}
#     },
#     "Env": [
#       "PATH=/usr/local/apache2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
#       "HTTPD_PREFIX=/usr/local/apache2",
#       "HTTPD_VERSION=2.4.48",
#       "HTTPD_SHA256=1bc826e7b2e88108c7e4bf43c026636f77a41d849cfb667aa7b5c0b86dbf966c",
#       "HTTPD_PATCHES="
#     ],
#     "Cmd": [
#       "httpd-foreground"
#     ],
#     "WorkingDir": "/usr/local/apache2",
#     "StopSignal": "SIGWINCH"
#   },
#   "rootfs": {
#     "type": "layers",
#     "diff_ids": [
#       "sha256:d000633a56813933cb0ac5ee3246cf7a4c0205db6290018a169d7cb096581046",
#       "sha256:2136d1b3a4af3d271affb9e933a184a9037b4616c6cecfcac1fd7f57574f6b0b",
#       "sha256:3453c54913b8e95e065ad29c28347d5c8fbb385a93906f7418a8f499b65f883e",
#       "sha256:d76ec8837f01b1d49b7f7f3943603c416bd2081a875c171b6d8e56e7ab98bddd",
#       "sha256:a5762756330aa73969fe946125b25d3ac19d7ee367e64afb6abf085693aaae81"
#     ]
#   },
#   "history": [
#     {
#       "created": "2021-09-03T01:21:46.511313656Z",
#       "created_by": "/bin/sh -c #(nop) ADD file:4ff85d9f6aa246746912db62dea02eb71750474bb29611e770516a1fcd217add in / "
#     },
#     {
#       "created": "2021-09-03T01:21:46.935145833Z",
#       "created_by": "/bin/sh -c #(nop)  CMD [\"bash\"]",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:53:52.987075336Z",
#       "created_by": "/bin/sh -c #(nop)  ENV HTTPD_PREFIX=/usr/local/apache2",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:53:53.175349131Z",
#       "created_by": "/bin/sh -c #(nop)  ENV PATH=/usr/local/apache2/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:53:54.034616515Z",
#       "created_by": "/bin/sh -c mkdir -p \"$HTTPD_PREFIX\" \t&& chown www-data:www-data \"$HTTPD_PREFIX\""
#     },
#     {
#       "created": "2021-09-03T06:53:54.254694804Z",
#       "created_by": "/bin/sh -c #(nop) WORKDIR /usr/local/apache2",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:53:59.27209269Z",
#       "created_by": "/bin/sh -c set -eux; \tapt-get update; \tapt-get install -y --no-install-recommends \t\tlibaprutil1-ldap \t; \trm -rf /var/lib/apt/lists/*"
#     },
#     {
#       "created": "2021-09-03T06:53:59.475002288Z",
#       "created_by": "/bin/sh -c #(nop)  ENV HTTPD_VERSION=2.4.48",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:53:59.662996109Z",
#       "created_by": "/bin/sh -c #(nop)  ENV HTTPD_SHA256=1bc826e7b2e88108c7e4bf43c026636f77a41d849cfb667aa7b5c0b86dbf966c",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:53:59.866912129Z",
#       "created_by": "/bin/sh -c #(nop)  ENV HTTPD_PATCHES=",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:56:39.249109879Z",
#       "created_by": "/bin/sh -c set -eux; \t\tsavedAptMark=\"$(apt-mark showmanual)\"; \tapt-get update; \tapt-get install -y --no-install-recommends \t\tbzip2 \t\tca-certificates \t\tdirmngr \t\tdpkg-dev \t\tgcc \t\tgnupg \t\tlibapr1-dev \t\tlibaprutil1-dev \t\tlibbrotli-dev \t\tlibcurl4-openssl-dev \t\tlibjansson-dev \t\tliblua5.2-dev \t\tlibnghttp2-dev \t\tlibpcre3-dev \t\tlibssl-dev \t\tlibxml2-dev \t\tmake \t\twget \t\tzlib1g-dev \t; \trm -r /var/lib/apt/lists/*; \t\tddist() { \t\tlocal f=\"$1\"; shift; \t\tlocal distFile=\"$1\"; shift; \t\tlocal success=; \t\tlocal distUrl=; \t\tfor distUrl in \t\t\t'https://www.apache.org/dyn/closer.cgi?action=download&filename=' \t\t\thttps://downloads.apache.org/ \t\t\thttps://www-us.apache.org/dist/ \t\t\thttps://www.apache.org/dist/ \t\t\thttps://archive.apache.org/dist/ \t\t; do \t\t\tif wget -O \"$f\" \"$distUrl$distFile\" && [ -s \"$f\" ]; then \t\t\t\tsuccess=1; \t\t\t\tbreak; \t\t\tfi; \t\tdone; \t\t[ -n \"$success\" ]; \t}; \t\tddist 'httpd.tar.bz2' \"httpd/httpd-$HTTPD_VERSION.tar.bz2\"; \techo \"$HTTPD_SHA256 *httpd.tar.bz2\" | sha256sum -c -; \t\tddist 'httpd.tar.bz2.asc' \"httpd/httpd-$HTTPD_VERSION.tar.bz2.asc\"; \texport GNUPGHOME=\"$(mktemp -d)\"; \tfor key in \t\tDE29FB3971E71543FD2DC049508EAEC5302DA568 \t\t13155B0E9E634F42BF6C163FDDBA64BA2C312D2F \t\t8B39757B1D8A994DF2433ED58B3A601F08C975E5 \t\t31EE1A81B8D066548156D37B7D6DBFD1F08E012A \t\tA10208FEC3152DD7C0C9B59B361522D782AB7BD1 \t\t3DE024AFDA7A4B15CB6C14410F81AA8AB0D5F771 \t\tEB138C6AF0FC691001B16D93344A844D751D7F27 \t\tCBA5A7C21EC143314C41393E5B968010E04F9A89 \t\t3C016F2B764621BB549C66B516A96495E2226795 \t\t937FB3994A242BA9BF49E93021454AF0CC8B0F7E \t\tEAD1359A4C0F2D37472AAF28F55DF0293A4E7AC9 \t\t4C1EADADB4EF5007579C919C6635B6C0DE885DD3 \t\t01E475360FCCF1D0F24B9D145D414AE1E005C9CB \t\t92CCEF0AA7DD46AC3A0F498BCA6939748103A37E \t\tD395C7573A68B9796D38C258153FA0CD75A67692 \t\tFA39B617B61493FD283503E7EED1EA392261D073 \t\t984FB3350C1D5C7A3282255BB31B213D208F5064 \t\tFE7A49DAA875E890B4167F76CCB2EB46E76CF6D0 \t\t39F6691A0ECF0C50E8BB849CF78875F642721F00 \t\t29A2BA848177B73878277FA475CAA2A3F39B3750 \t\t120A8667241AEDD4A78B46104C042818311A3DE5 \t\t453510BDA6C5855624E009236D0BC73A40581837 \t\t0DE5C55C6BF3B2352DABB89E13249B4FEC88A0BF \t\t7CDBED100806552182F98844E8E7E00B4DAA1988 \t\tA8BA9617EF3BCCAC3B29B869EDB105896F9522D8 \t\t3E6AC004854F3A7F03566B592FF06894E55B0D0E \t\t5B5181C2C0AB13E59DA3F7A3EC582EB639FF092C \t\tA93D62ECC3C8EA12DB220EC934EA76E6791485A8 \t\t65B2D44FE74BD5E3DE3AC3F082781DE46D5954FA \t\t8935926745E1CE7E3ED748F6EC99EE267EB5F61A \t\tE3480043595621FE56105F112AB12A7ADC55C003 \t\t93525CFCF6FDFFB3FD9700DD5A4B10AE43B56A27 \t\tC55AB7B9139EB2263CD1AABC19B033D1760C227B \t; do \t\tgpg --batch --keyserver keyserver.ubuntu.com --recv-keys \"$key\"; \tdone; \tgpg --batch --verify httpd.tar.bz2.asc httpd.tar.bz2; \tcommand -v gpgconf && gpgconf --kill all || :; \trm -rf \"$GNUPGHOME\" httpd.tar.bz2.asc; \t\tmkdir -p src; \ttar -xf httpd.tar.bz2 -C src --strip-components=1; \trm httpd.tar.bz2; \tcd src; \t\tpatches() { \t\twhile [ \"$#\" -gt 0 ]; do \t\t\tlocal patchFile=\"$1\"; shift; \t\t\tlocal patchSha256=\"$1\"; shift; \t\t\tddist \"$patchFile\" \"httpd/patches/apply_to_$HTTPD_VERSION/$patchFile\"; \t\t\techo \"$patchSha256 *$patchFile\" | sha256sum -c -; \t\t\tpatch -p0 < \"$patchFile\"; \t\t\trm -f \"$patchFile\"; \t\tdone; \t}; \tpatches $HTTPD_PATCHES; \t\tgnuArch=\"$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)\"; \tCFLAGS=\"$(dpkg-buildflags --get CFLAGS)\"; \tCPPFLAGS=\"$(dpkg-buildflags --get CPPFLAGS)\"; \tLDFLAGS=\"$(dpkg-buildflags --get LDFLAGS)\"; \t./configure \t\t--build=\"$gnuArch\" \t\t--prefix=\"$HTTPD_PREFIX\" \t\t--enable-mods-shared=reallyall \t\t--enable-mpms-shared=all \t\t--enable-pie \t\tCFLAGS=\"-pipe $CFLAGS\" \t\tCPPFLAGS=\"$CPPFLAGS\" \t\tLDFLAGS=\"-Wl,--as-needed $LDFLAGS\" \t; \tmake -j \"$(nproc)\"; \tmake install; \t\tcd ..; \trm -r src man manual; \t\tsed -ri \t\t-e 's!^(\\s*CustomLog)\\s+\\S+!\\1 /proc/self/fd/1!g' \t\t-e 's!^(\\s*ErrorLog)\\s+\\S+!\\1 /proc/self/fd/2!g' \t\t-e 's!^(\\s*TransferLog)\\s+\\S+!\\1 /proc/self/fd/1!g' \t\t\"$HTTPD_PREFIX/conf/httpd.conf\" \t\t\"$HTTPD_PREFIX/conf/extra/httpd-ssl.conf\" \t; \t\tapt-mark auto '.*' > /dev/null; \t[ -z \"$savedAptMark\" ] || apt-mark manual $savedAptMark; \tfind /usr/local -type f -executable -exec ldd '{}' ';' \t\t| awk '/=>/ { print $(NF-1) }' \t\t| sort -u \t\t| xargs -r dpkg-query --search \t\t| cut -d: -f1 \t\t| sort -u \t\t| xargs -r apt-mark manual \t; \tapt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \t\thttpd -v"
#     },
#     {
#       "created": "2021-09-03T06:56:39.608580614Z",
#       "created_by": "/bin/sh -c #(nop)  STOPSIGNAL SIGWINCH",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:56:39.863927344Z",
#       "created_by": "/bin/sh -c #(nop) COPY file:c432ff61c4993ecdef4786f48d91a96f8f0707f6179816ccb98db661bfb96b90 in /usr/local/bin/ "
#     },
#     {
#       "created": "2021-09-03T06:56:40.05896237Z",
#       "created_by": "/bin/sh -c #(nop)  EXPOSE 80",
#       "empty_layer": true
#     },
#     {
#       "created": "2021-09-03T06:56:40.263369583Z",
#       "created_by": "/bin/sh -c #(nop)  CMD [\"httpd-foreground\"]",
#       "empty_layer": true
#     }
#   ]
# }


###### Now let's look to layer, first we look to first layer, the base layer.
###### it's tar.gz file so we need to extract it.
mkdir httpd-unpacked
cd httpd-unpacked
tar -xvf ../httpd/blobs/sha256/a330b6cecb98cd2425fd25fce36669073f593b3176b4ee14731e48c05d678cdd
# root@test-logs:~/httpd-unpacked# ls -lhAF
# total 76K
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 bin/
# drwxr-xr-x  2 root root 4.0K Jun 13  2021 boot/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 dev/
# drwxr-xr-x 28 root root 4.0K Sep  2  2021 etc/
# drwxr-xr-x  2 root root 4.0K Jun 13  2021 home/
# drwxr-xr-x  7 root root 4.0K Sep  2  2021 lib/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 lib64/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 media/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 mnt/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 opt/
# drwxr-xr-x  2 root root 4.0K Jun 13  2021 proc/
# drwx------  2 root root 4.0K Sep  2  2021 root/
# drwxr-xr-x  3 root root 4.0K Sep  2  2021 run/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 sbin/
# drwxr-xr-x  2 root root 4.0K Sep  2  2021 srv/
# drwxr-xr-x  2 root root 4.0K Jun 13  2021 sys/
# drwxrwxrwt  2 root root 4.0K Sep  2  2021 tmp/
# drwxr-xr-x 10 root root 4.0K Sep  2  2021 usr/
# drwxr-xr-x 11 root root 4.0K Sep  2  2021 var/

###### it's look like complete filesystem.
###### Now lets look another layer. it only has changes
###### some files begin with '.wh.' that shows some file or directory should be removed. they are called wipe out files.
# tar -xvf ../httpd/blobs/sha256/14e3dd65f04dcce813a2bfca1a76d5982fac79817dc9470a0f6abc2e51708b97
# usr/
# usr/local/
# usr/local/apache2/
# usr/local/apache2/.wh..wh..opq



#
#                                                 image-spec
#
#
#                                                                         _______________________
#                                                                        /                       \
#                                                                       |       Index file        |
#                                                                        \_______________________/
#                                                                       /
#                                                                      /
#                            3974rt89fgf234  _______________________ </
#                                           /                       \
#                                          |      Image manifest     |
#                                           \_______________________/  :latest
#                                             /                      \
#                                            /                        \
#    9834tbgidugh  _______________________ </                          \> _______________________  34141089fgdfg
#                 /                       \                              /                       \
#                |      Image Config       |                            |      Image layers       |
#                 \_______________________/                              \_______________________/
#             Define how to run the the image                                   .tar archives
#


###### Tho run a container we don't need container image, we need container bundle. keep going :)
