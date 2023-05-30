# TODO use fixed jina version for deterministic execution
FROM jinaai/jina:test-pip

# setup the workspace
COPY . /workspace
WORKDIR /workspace

ENTRYPOINT ["jina", "executor", "--uses", "config.yml"]
