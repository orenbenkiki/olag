## Rakefile ##

Olag's Rakefile is a good example of how to use Olag's classes to create a
full-featured gem Rakefile:

[[Rakefile|named_chunk_with_containers]]

The overall Rakefile structure is as follows:

* A first line sets up the Ruby module load path to begin with
  the current gem's `lib` directory. This standard idiom ensures we have access
  to the current gem.

* The next line imports Olag's `rake` support module.

* This is followed by setting up the gem specification, which is enhanced by
  Olag using monkey-patching.

* Finally, Olag::Rake sets up the following tasks (as reported by `rake -T`):
      rake all               # Version, verify, document, package
      rake analyze           # Analyze source code
      rake changelog         # Update ChangeLog from Git
      rake clean             # Remove any temporary products.
      rake clean_codnar      # Clean all split chunks
      rake clobber           # Remove any generated file.
      rake clobber_codnar    # Remove woven HTML documentation
      rake clobber_coverage  # Remove rcov products for coverage
      rake clobber_package   # Remove package products
      rake clobber_rdoc      # Remove rdoc products
      rake codnar            # Build the code narrative HTML
      rake codnar_split      # Split all files into chunks
      rake codnar_weave      # Weave chunks into HTML
      rake commit            # Git commit process
      rake coverage          # Test code covarage with RCov
      rake doc               # Generate all documentation
      rake first_commit      # Perform the 1st (main) Git commit
      rake flay              # Check for duplicated code with Flay
      rake gem               # Build the gem file olag-0.1.2.gem
      rake package           # Build all the packages
      rake rdoc              # Build the rdoc HTML Files
      rake reek              # Check for smelly code with Reek
      rake repackage         # Force a rebuild of the package files
      rake rerdoc            # Force a rebuild of the RDOC files
      rake roodi             # Check for smelly code with Roodi
      rake saikuro           # Check for complex code with Saikuro
      rake second_commit     # Perform the 2nd (amend) Git commit
      rake test              # Run tests for test
      rake verify            # Test, coverage, analyze code
      rake version           # Update version file from Git

### Gem Specification ###

The gem specification is provided as usual:

[[Gem specification|named_chunk_with_containers]]

However, the Gem::Specification class is monkey-patched to automatically
several of the specification fields, and adding some new ones:

[[lib/olag/gem_specification.rb|named_chunk_with_containers]]

### Rake tasks ###

The Olag::Rake class sets up the tasks listed above as follows:

[[lib/olag/rake.rb|named_chunk_with_containers]]

#### Task utilities ####

The following utilities are used to create the different tasks. It would have
be nicer if Rake had treated the task description as just another task
property.

[[Task utilities|named_chunk_with_containers]]

#### Verify the gem ####

The following tasks verify that the gem is correct. Testing for 100% code
coverage seems excessive but in reality it isn't that hard to do, and is really
only a modest form of test coverage verification.

[[Verify gem functionality|named_chunk_with_containers]]

The following tasks verify that the code is squeacky-clean. While passing the
code through all these verifiers seems excessive, it isn't that hard to achieve
in practice. There were several times I did refactorings "just to satisfy
`reek` (or `flay`)" and ended up with an unexpected code improvement. Anyway,
if you aren't a youch OCD about this sort of thing, Olag is probably not for
you :-)

[[Analyze the source code|named_chunk_with_containers]]

#### Generate Documentation ####

The following tasks generate the usual RDoc documentation, required to make the
gem behave well in the Ruby tool ecosystem:

[[Generate RDoc documentation|named_chunk_with_containers]]

The following tasks generate the Codnar documentation (e.g., the document you
are reading now), which goes beyond RDoc to provide an end-to-end linear
narrative describing the gem:

[[Generate Codnar documentation|named_chunk_with_containers]]

Codnar is very configurable, and the above provides a reasonable default
configuration for pure Ruby gems. You can modify the CODNAR_CONFIGURATIONS
array before creating the Rake object, by unshifting additional/overriding
patterns into it. For example, you may choose to use GVim for syntax
highlighting. This will cause splitting to become much slower, but the
generated HTML will already include the highlighting markup so it will display
instantly. Or, you may have additional source file types (Javascript, CSS,
HTML, C, etc.) to be highlighted.

#### Automate Git commit process ####

In an ideal world, committing to Git would be a simple matter of typing `git
commit -m "..."`. In our case, things get a bit complicated.

There is some information that we need to extract out of Git and inject into
our files (to be committed). Since Git pre-commit hooks do not allow us to
modify any source files, this turns commit into a two-phase process: we do an
initial commit, update some files, then `git commit --amend` to merge them with
the first commit.

[[Automate Git commit process|named_chunk_with_containers]]

The first piece of information we need to extract from Git is the current build
number, which needs to be injected into the gem's version number:

[[lib/olag/version.rb|named_chunk_with_containers]]

Documentation generation will depend on the content (and therefore modification
time) of this file. Luckily, we can update this number before the first commit,
and we can ensure it only touches the file if there is a real change, to avoid
unnecessary documentation regeneration:

[[lib/olag/update_version.rb|named_chunk_with_containers]]

The second information we extract from Git is the ChangeLog file. Here,
obviously, the ChangeLog needs to include the first commit's message, so we are
forced to regenerate the file and amend Git's history with a second commit:

[[lib/olag/change_log.rb|named_chunk_with_containers]]

## Utility classes ##

Olag provides a set of utility classes that are useful in implementing
well-behaved gems.

### Unindeting text ###

When using "here documents" (`<<EOF` data), it is nice to be able to indent the
data to match the surrounding code. There are other cases where it is useful to
"unindent" multi-line text. The following tests demonstrates using the
`unindent` function:

[[test/unindent_text.rb|named_chunk_with_containers]]

And here is the implementation extending the built-in String class:

[[lib/olag/string_unindent.rb|named_chunk_with_containers]]

### Accessing gem data files ###

Sometimes it is useful to package some files inside a gem, to be read by user
code. This is of course trivial for Ruby code files (just use `require`) but
not trivial if you want, say, to include some CSS files in your gem for
everyone to use. Olag provides a way to resolve the path of any file in any gem
(basically replicating what `require` does). Here is a simple test of using
this functionality:

[[test/access_data_files.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/olag/data_files.rb|named_chunk_with_containers]]

### Simulating objects with Hash tables ###

Javascript has an interesting convention where `hash["key"]` and `hash.key`
mean the same thing. This is very useful in cutting down boilerplate code, and
it also makes your data serialize to very clean YAML. Unlike OpenStruct, you do
not need to define all the members in advance, and you can alternate between
the `.key` and `["key"]` forms as convenient for any particular piece of code.
The down side is that you lose any semblance of type checking - misspelled
member names and other errors are silently ignored. Well, that's what we have
unit tests for, right? :-)

Olag provides an extension to the Hash class that provides the above, for these
who have chosen to follow the dark side of the force. Here is a simple test
demonstrating using this ability:

[[test/missing_keys.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/olag/hash_struct.rb|named_chunk_with_containers]]

### Collecting errors ###

In library code, it is bad practice to terminate the program on an error.
Raising an exception is preferrable, but that forces you to abort the
processing. In some cases, it is preferrable to collect the error, skip a bit
of processing, and continue (if only for detecting additional errors). For
example, one would expect a compiler to emit more than just the first syntax
error message.

Olag provides an error collection class that also automatically formats the
error to indicate its location. Here is a simple test that demonstrates
collecting errors:

[[test/collect_errors.rb|named_chunk_with_containers]]

Which uses a mix-in that helps writing tests that use errors:

[[lib/olag/test/with_errors.rb|named_chunk_with_containers]]

Here is the actual implementation:

[[lib/olag/errors.rb|named_chunk_with_containers]]

### Testing with a fake file system ###

Sometimes tests need to muck around with disk files. One way to go about it is
to create a temporary disk directory, work in there, and clean it up when done.
Another, simpler way is to use the FakeFS file system, which captures all(most)
of Ruby's file operations and redirect them to an in-memory fake file system.
Here is a mix-in that helps writing tests using FakeFS (we will use it below
when running applications inside unit tests):

[[lib/olag/test/with_fakefs.rb|named_chunk_with_containers]]

### Testing with a temporary file ###

When running external programs, actually generating a temporary disk file is
sometimes inevitable. Of course, such files need to be cleaned up when the test
is done. Here is a mix-in that helps writing tests using such temporary files:

[[lib/olag/test/with_tempfile.rb|named_chunk_with_containers]]

### Testing in general ###

Rather than requiring each of the above test mix-in modules on its own, it is
convenient to just `require "olag/test"` and be done:

[[lib/olag/test.rb|named_chunk_with_containers]]

## Applications ##

Writing an application requires a lot of boilerplate. Olag provides an
Application base class that handles standard command line flags, execution from
within tests, and errors collection.

Here is a simple test for running such an application from unit tests:

[[test/run_application.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/olag/application.rb|named_chunk_with_containers]]

It makes use of the following utility class, for saving and restoring the
global state when running an application in a test:

[[lib/olag/globals.rb|named_chunk_with_containers]]

## License ##

Olag is published under the MIT license:

[[LICENSE|named_chunk_with_containers]]
