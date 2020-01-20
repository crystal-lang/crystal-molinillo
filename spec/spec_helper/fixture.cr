require "json"

class Molinillo::Fixture
  class Dependency
    JSON.mapping(
      name: String,
      version: String,
      dependencies: Array(Dependency)
    )
  end

  JSON.mapping(
    name: String,
    index: String?,
    requested: Hash(String, String),
    base: Array(Dependency),
    resolved: Array(Dependency),
    conflicts: Array(String)
  )
end
