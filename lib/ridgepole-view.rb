# frozen_string_literal: true

require "tsort"
require "ridgepole"
require "scenic"

require "ridgepole/view/version"
require "ridgepole/view/view_definition"
require "ridgepole/view/dsl_parser/context"
require "ridgepole/view/dsl_parser"
require "ridgepole/view/dumper"
require "ridgepole/view/diff"
require "ridgepole/view/delta"

Ridgepole::DSLParser::Context.prepend(Ridgepole::View::DSLParser::Context)
Ridgepole::DSLParser.prepend(Ridgepole::View::DSLParser)
Ridgepole::Dumper.prepend(Ridgepole::View::Dumper)
Ridgepole::Diff.prepend(Ridgepole::View::Diff)
Ridgepole::Delta.prepend(Ridgepole::View::Delta)
