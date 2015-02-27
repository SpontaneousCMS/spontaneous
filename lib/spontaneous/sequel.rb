require "sequel"

Sequel.extension :inflector

# See http://sequel.jeremyevans.net/rdoc/classes/Sequel/Timezones.html
# UTC is more performant than :local (or 'nil' which just fallsback to :local)
# A basic profiling run gives a 2 x performance improvement of :utc over :local
# With ~240 rows, timing ::Content.all gives:
#
#     :utc     ~0.04s
#     :local   ~0.08s
#
# DB timestamps are only shown in the editing UI & could be localized there per-user
Sequel.default_timezone = :utc
