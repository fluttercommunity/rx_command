## [0.0.1] - 10.04.2018

* Initial release.

## [0.0.2] - 10.04.2018

* Removed the necessity of type `Unit`. Instead now `Null` is used

## [0.0.3] - 10.04.2018

* Trying to fix the documentation link

## [1.0.0] - 11.04.2018

* Made RxCommand a callable class so that you now can directly assign it to your widget handlers

## [1.0.1] - 11.04.2018

* Small update in docs

## [1.0.2] - 16.04.2018

* Added CommandResult, now RxCommand is itself an Observable that emits CommandResults

## [1.0.3] - 17.04.2018

* RxCommands created by RxCommand.createFromStream no longer emit a final event after the last item of the source stream was received

## [1.0.4] - 19.04.2018

* Added MockCommand 

## [1.0.5] - 20.04.2018

* Improvements and docs for MockCommand 

## [1.0.6] - 20.04.2018

* Polishing and including `analysis_options.yaml` 

## [1.0.7] - 20.04.2018

* Forgot to run tests and missed an error that I introduced following an analyzer hint that I should use `const` instead of `new` 

## [1.0.8] - 25.04.2018

* RxCommand no longer issues an initial `CommandResult(null,null,false)` unless you set `emitInitialCommandResult: true` when creating the command.
