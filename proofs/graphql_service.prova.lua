--- Render-verification suite for the Java GraphQL service archetype: each persistence variant lays
--- out correctly and is fully rendered, and the hollow (None) rendering stays hollow.
---
--- The BEHAVIORAL bar — CRUD through the production image, the platform env contract, health/
--- metrics/structured logs, both name shapes — lives in tests/standards_test.lua (the shared
--- p6m standards suite), fully containerized: docker is the only requirement. Compile coverage
--- is containerized too: the standards SUT image builds compile the persistence variants, and
--- the hollow rendering is proven compilable by building its production Dockerfile here — no
--- host toolchain is ever required.

local p6m = require("p6m")

local SRC = "."

local BASE_ANSWERS = {
  project_name = "example-service",
  solution_name = "acme-platform",
  entity_name = "example",
  group_id         = "acme.platform",
  artifactory_host = "acme.jfrog.io",
  image_registry   = "ghcr.io/acme",
}

local function answers_with(extra)
  local out = {}
  for k, v in pairs(BASE_ANSWERS) do out[k] = v end
  for k, v in pairs(extra) do out[k] = v end
  return out
end

-- Files the persistence scaffold adds (relative to the rendered project root). Absent from "None".
local PERSISTENCE_FILES = {
  "example-service-persistence/pom.xml",
  "example-service-persistence/src/main/java/acme/platform/exampleservice/persistence/PersistenceConfig.java",
  "example-service-persistence/src/main/java/acme/platform/exampleservice/persistence/Example.java",
  "example-service-persistence/src/main/java/acme/platform/exampleservice/persistence/ExampleRepository.java",
  "example-service-persistence/src/main/resources/db/migration/V1__init.sql",
  "example-service-persistence/src/main/resources/db/migration/V2__create_examples.sql",
  "example-service-graphql/src/main/java/acme/platform/exampleservice/graphql/ExampleGraphqlController.java",
  "example-service-server/src/main/resources/application-persistence.yaml",
}

-- Base + GraphQL protocol module; present in every rendering (the schema always carries the
-- standard API surface; resolvers arrive with a persistence flavor).
local BASE_FILES = {
  "pom.xml",
  "example-service-bom/pom.xml",
  "example-service-core/pom.xml",
  "example-service-server/pom.xml",
  "example-service-server/src/main/java/acme/platform/exampleservice/server/Application.java",
  "example-service-server/src/main/resources/application.yaml",
  "example-service-integration-tests/pom.xml",
  "example-service-graphql/pom.xml",
  "example-service-graphql/src/main/resources/graphql/example_service.graphqls",
  ".dockerignore",
  ".github/workflows/build.yaml",
}

for _, persistence in ipairs({ "PostgreSQL", "MySQL" }) do
  local label = "java-graphql[" .. persistence .. "]"

  local expected = {}
  for _, f in ipairs(BASE_FILES) do expected[#expected + 1] = f end
  for _, f in ipairs(PERSISTENCE_FILES) do expected[#expected + 1] = f end

  archetect.verify{
    name = label,
    source = SRC,
    answers = answers_with{ persistence = persistence },
    project_dir = "example-service",
    expected_files = expected,
    yaml_globs = { ".platform/kubernetes/**/*.yaml" },
  }
end

-- The hollow rendering stays hollow: no persistence module, no scaffold files (the schema keeps
-- the standard surface; no resolvers back it yet).
local none_project = prova.fixture("java-graphql[None]:project", Scope.File, function(ctx)
  return archetect.render{
    source = SRC,
    answers = answers_with{ persistence = "None" },
    destination = ctx:tempdir("render1"),
    defaults = true,
  }
end)

archetect.verify(none_project, {
  name = "java-graphql[None]",
  project_dir = "example-service",
  expected_files = BASE_FILES,
  absent_files = PERSISTENCE_FILES,
  yaml_globs = { ".platform/kubernetes/**/*.yaml" },
})

-- Containerized compile proof for the hollow rendering: the persistence variants are compiled by
-- the standards suite's SUT image builds; None never boots there, so prove it compiles by
-- building its production Dockerfile (build success = it compiles; no boot needed).
prova.group("java-graphql[None]:image", { requires = { "docker" } }, function(g)
  g:test("production image builds (compiles the hollow rendering)", function(t)
    local root = t:use(none_project):dir("example-service")
    local image = docker.build{
      context = root.path,
      dockerfile = ".platform/docker/prd/Dockerfile",
    }
    t:expect(image, "built image ref"):never():is_empty()
  end)
end)

-- CI parity (S10): the rendered project's own Build workflow path — the build.yaml's single
-- 'mvn verify --no-transfer-progress' on a fresh clone, in the toolchain image. The Dockerfile
-- and CI are two independent build paths; S10 holds the second. The hollow render suffices:
-- resource variants change dependencies, not the command path.
prova.group("java-graphql[None]:ci", { requires = { "docker" }, tags = { "standards" } }, function(g)
  p6m.standards.ci_parity(g, none_project, {
    stack = "java",
    project_dir = "example-service",
    name = "java-graphql",
  })
end)
