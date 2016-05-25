Includes dotnet watch for live reloading your application when a file is changed.

How to use it:
- Create a .Net core web application. Make sure that project.json contains a reference to the dotnet watch tool:

"tools": {
    "Microsoft.DotNet.Watcher.Tools": {
      "version": "1.0.0-*",
      "imports": "portable-net451+win8"
    }
  }

- Add a docker file containing

FROM sequentia/dotnet-watch-core-rc2
VOLUME /app
WORKDIR /app
ENV ASPNETCORE_SERVER.URLS http://*:2001
ENV ASPNETCORE_ENVIRONMENT Development
EXPOSE 2001
ENTRYPOINT ["/startscript.sh"]

- Build the project docker image

docker build -t MyApplication .

- Run the application by mapping the application folder (containing project.json) to the container /app and map the listening http port (2001 in this example)

docker run -it -v %cd%:/app -p 2001:2001 MyApplication

- The application will start and dotnet watch will executed. Any changes made to the source code outside the docker container will trigger a recompilation of the application inside the container.