defmodule Mix.Tasks.Docker.Build do
  use Mix.Task

  @shortdoc "Docker utils for building releases"
  def run(args) do
    Mix.Task.run("docker", args)
  end
end
