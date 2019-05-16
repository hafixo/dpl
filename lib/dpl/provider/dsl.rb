module Dpl
  class Provider < Cl::Cmd
    # DSL available on the provider's class body.
    #
    # Use this to declare various features, requirements, and attributes that
    # apply to your provider.
    module Dsl
      include Squiggle

      # @!method opt
      # Declare command line options that the provider supports.
      #
      # This method is inherited from the base class `Cl::Cmd` which is defined
      # in the Rubygem `Cl`. See the gem's documentation for details on how
      # to declare command line options.
      #
      # @see https://github.com/svenfuchs/cl

      # Mark the provider as deprecated, with a warning message that will be
      # printed to the stderr.
      def deprecated(msg = nil)
        msg ? @deprecated = msg : @deprecated
      end

      # Whether or not the provider has deprecation warnings.
      def deprecated?
        !!@deprecated
      end

      # Mark the provider experimental, a warning will be printed to stderr.
      def experimental
        @experimental = true
      end

      # Whether or not the provider has been marked experimental.
      def experimental?
        !!@experimental
      end

      # Declare APT packages the provider depends on. These will be installed
      # during the `before_install` stage using `apt-get install`, unless the
      # given cmd is already available according to `which [cmd]`.
      #
      # @param package [String] Package name (required).
      # @param cmd     [String] Executable command installed by that package (optional, defaults to the package name).
      #
      # @return Previously declared apt packages if no arguments were given.
      def apt(package = nil, cmd = nil)
        package ? apt << [package, cmd].compact : @apt ||= []
      end

      # Whether or not the provider depends on any apt packages.
      def apt?
        !!@apt
      end

      # Declare additional paths to Ruby gem source code that this provider
      # requires.
      #
      # These gems will be installed, and files required at runtime, during the
      # `before_init` stage (not at install time, and/or load time), unless they
      # are already installed.
      #
      # @param name    [String] Ruby gem name (required)
      # @param version [String] Ruby gem version (required)
      # @param opts    [Hash] options
      # @option opts [Array<String>, String] :require A single path or a list of paths to source files to require from this Ruby gem. If not given the name of the gem will be assumed to be the path to be required.
      #
      # @return Previously declared gems if no arguments were given
      def gem(name = nil, version = nil, opts = {})
        name ? gem << [name, version, opts] : @gem ||= []
      end

      def gem?
        !!@gem
      end

      # Declare NPM packages the provider depends on. These will be installed
      # during the `before_install` stage using `npm install -g`, unless the
      # given cmd is already available according to `which [cmd]`.
      #
      # @param package [String] Package name (required).
      # @param cmd     [String] Executable command installed by that package (optional, defaults to the package name).
      #
      # @return Previously declared NPM packages if no arguments are given.
      def npm(package = nil, cmd = nil)
        package ? npm << [package, cmd].compact : @npm ||= []
      end

      # Whether or not the provider depends on any NPM packages.
      def npm?
        !!@npm
      end

      # Declare Python packages the provider depends on. These will be installed
      # during the `before_install` stage using `pip install --user`. A previously
      # installed package is uninstalled before that, but only if `version` was
      # given.
      #
      # @param package [String] Package name (required).
      # @param cmd     [String] Executable command installed by that package (optional, defaults to the package name).
      # @param version [String] Package version (optional).
      #
      # @return Previously declared Python packages if no arguments are given.
      def pip(package = nil, cmd = nil, version = nil)
        package ? pip << [package, cmd, version].compact : @pip ||= []
      end

      # Whether or not the provider depends on any Python packages.
      def pip?
        !!@pip
      end

      # Declare the full name of the provider. Required if the proper provider
      # name does not match the provider's class name.
      #
      # @param name [String] The provider's full name
      # @return The previously declared full name if no argument is given
      def full_name(name = nil)
        name ? @full_name = name : @full_name || self.name.split('::').last
      end

      # Summary of the provider's functionality.
      def summary(summary = nil)
        summary ? super : @summary || "#{full_name} deployment provider"
      end

      # Declare shell commands used by the provider.
      #
      # This exists so shell commands used can be separated from the
      # implementation that runs them. This is useful in order to easily get an
      # overview of all shell commands used by a provider on one hand, and in
      # order to keep the implementation code focussed on the logic and
      # functionality it provides, rather than the details of (potentially long
      # winded) shell commands.
      #
      # For example, a shell command declared on the class body like so:
      #
      #   ```ruby
      #   cmds git_push: 'git push -f %{target}'
      #   ```
      #
      # can be used in the deploy stage like so:
      #
      #   ```ruby
      #   def deploy
      #     shell :git_push
      #   end
      #   ```
      #
      # The variable `%{target}` will be interpolated by calling the method
      # `target` on the provider instance, so it will expect that method to
      # exist.
      #
      # @param cmds [Hash] Commands to declare.
      # @return Previously declared cmds if no argument is given.
      #
      # @see Dpl::Ctx::Bash#shell Ctx::Bash#shell for more details on how to call shell
      # commands.
      def cmds(cmds = nil)
        return self.cmds.update(cmds) if cmds
        @cmds ||= self == Provider ? {} : superclass.cmds.dup
      end

      # Declare error messages that are raised if a shell command fails.
      #
      # This exists so error messages can be separated from the implementation
      # that uses them. This is useful in order to easily get an overview of
      # all error messages used by a provider on one hand, and in order to keep
      # the implementation code focussed on the logic and functionality it
      # provides, rather than the details of (potentially long winded) error
      # message strings.
      #
      # The method `shell` takes an option `assert`, which, if set to `true`
      # will raise an error if the given shell command fails (returns a
      # non-zero exit code). In this case the error message declared using
      # `errs` will be used to raise with the eror.
      #
      # For example, an error message declared on the class body like so:
      #
      #   ```ruby
      #   errs git_push: 'Failed to push to %{target}'
      #   ```
      #
      # will be included to the raised error if method `shell` was called
      # with the option `assert: true`, and the given command has failed:
      #
      #   ```ruby
      #   def deploy
      #     shell :git_push, assert: true
      #   end
      #   ```
      #
      # The variable `%{target}` will be interpolated by calling the method
      # `target` on the provider instance, so it will expect that method to
      # exist.
      #
      # @param errs [Hash] Error messages to declare.
      # @return Previously declared errs if no argument is given.
      #
      # See Dpl::Ctx::Bash#shell for more details on how to call shell
      # commands.
      def errs(errs = nil)
        return self.errs.update(errs) if errs
        @errs ||= self == Provider ? {} : superclass.errs.dup
      end

      # Declare other messages, such as info level log output, warnings, or
      # custom strings, such as commit messages or descriptions.
      #
      # This exists so various messages can be separated from the
      # implementation that uses them. This is useful in order to easily get an
      # overview of all error messages used by a provider on one hand, and in
      # order to keep the implementation code focussed on the logic and
      # functionality it provides, rather than the details of (potentially long
      # winded) message strings.
      #
      # For example, a message declared on the class body like so:
      #
      #   ```ruby
      #   msgs login: 'Logging in to the service %{full_name}'
      #   ```
      #
      # could be used by the implementation like so:
      #
      #   ```ruby
      #   def login
      #     info :login
      #   end
      #   ```
      #
      # The variable `%{full_name}` will be interpolated by calling the method
      # `full_name` on the provider instance, so it will expect that method to
      # exist.
      #
      # It is possible to use msgs in order to declare and use custom messages,
      # e.g. for the commit message on a commit a provider needs to create, or
      # a description that needs to be included to an API call.
      #
      # For example, a message declared on the class body like so:
      #
      #   ```ruby
      #   cmds git_commit: 'git commit -am "%{commit_msg}"'
      #   msgs commit_msg: 'Commit build artifacts on build %{build_number}'
      #   ```
      #
      # could be used by the implementation like so:
      #
      #   ```ruby
      #   def create_commit
      #     shell :git_commit
      #   end
      #
      #   def commit_msg
      #     interpolate(msg(:commit_msg))
      #   end
      #   ```
      #
      # Note that in cases where builtin methods such as `shell`, `info`,
      # `warn` etc. are not used the method `interpolate` needs to be used in
      # order to interpolate variables used in a message (if any).
      #
      # @param msgs [Hash] Messages to declare.
      # @return Previously declared msgs if no argument is given.
      def msgs(msgs = nil)
        return self.msgs.update(msgs) if msgs
        @msgs ||= self == Provider ? {} : superclass.msgs.dup
      end

      # Declare artifacts, such as executables during the `install` stage that
      # need to be kept during `cleanup`.
      #
      # @param paths [String] Paths to artifacts to keep during `cleanup`
      # @return Previously declared artifacts to keep if no argument is given.
      def keep(*paths)
        paths.any? ? keep.concat(paths) : @keep ||= []
      end

      # Declare features that the provider needs.
      #
      # Known features currently are:
      #
      # * `ssh_key`: Generates a temporary, per-build SSH key, and calls the
      #   methods `add_key` and `remove_key` if the provider defines them.
      #   This gives providers the opportunity to install this key on their
      #   service, and remove it after the deployment has finished.
      # * `git`: Populates the git config.user and config.email attributes,
      #   unless present.
      # * `git_http_user_agent`: Changes the environment variable
      #   `GIT_HTTP_USER_AGENT` to the one generated by `user_agent`. This
      #   gives providers the opportunity to identify and track coming from
      #   Travis CI and/or dpl.
      #
      # @param features [Symbol] Features to activate for this provider
      # @return Previously declared features needed if no argument is given.
      def needs(*features)
        features.any? ? needs.concat(features) : @needs ||= []
      end

      # Whether or not the provider has declared any features it needs.
      def needs?(feature)
        needs.include?(feature)
      end

      # Generates a useragent string that identifies the current dpl version,
      # and whether it runs int he context of Travis CI. Can include arbitrary
      # extra strings or key value pairs (passed as String or Hash arguments).
      # @param strs [String(s) or Hash(es)] Additional strings or key value pairs to include to the useragent string.
      # @return [String] The useragent string
      def user_agent(*strs)
        strs.unshift "dpl/#{Dpl::VERSION}"
        strs.unshift 'travis/0.1.0' if ENV['TRAVIS']
        strs = strs.flat_map { |e| Hash === e ? e.map { |k, v| "#{k}/#{v}" } : e }
        strs.join(' ').gsub(/\s+/, ' ').strip
      end

      def ruby_version
        Gem::Version.new(RUBY_VERSION)
      end

      def ruby_pre_2_3?
        ruby_version < Gem::Version.new('2.3.0')
      end

      def ruby_pre_2_4?
        ruby_version < Gem::Version.new('2.4.0')
      end
    end
  end
end
