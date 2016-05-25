FROM buildpack-deps:trusty-scm
MAINTAINER Eduardo Lucas
ENV DOTNET_VERSION=1.0.0-preview1-002702

# Work around https://github.com/dotnet/cli/issues/1582 until Docker releases a
# fix (https://github.com/docker/docker/issues/20818). This workaround allows
# the container to be run with the default seccomp Docker settings by avoiding
# the restart_syscall made by LTTng which causes a failed assertion.
ENV LTTNG_UST_REGISTER_TIMEOUT 0

# Install dotnet, ignores the key server
RUN echo "deb [arch=amd64] http://apt-mo.trafficmanager.net/repos/dotnet/ trusty main" > /etc/apt/sources.list.d/dotnetdev.list
RUN apt-get update
RUN apt-get install -y --force-yes --no-install-recommends dotnet-dev-${DOTNET_VERSION}
RUN rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV ASPNETCORE_URLS="http://*:5000"
ENV ASPNETCORE_ENVIRONMENT="Staging"

# Activate the polling based dotnet watch mechanism for the mounted volume
ENV USE_POLLING_FILE_WATCHER=true

# Copy the debugger
COPY /clrdbg /clrdbg
RUN chmod 700 -R /clrdbg

# Preload the .net assemblies
RUN mkdir /dotnet
COPY project.json /dotnet
COPY nuget.config /dotnet
WORKDIR /dotnet
RUN ["dotnet", "restore"]

# Set working directory
RUN mkdir /app
WORKDIR /app

# Open up port
EXPOSE 5000

# calls dotnet restore (loads your app dependencies) and dotnet watch (starts your app) via a shell script
COPY startscript.sh /
RUN chmod 755 /startscript.sh
ENTRYPOINT ["/startscript.sh"]

