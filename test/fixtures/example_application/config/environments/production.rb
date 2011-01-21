

over_ridden :production_value

# Sets the 'nice' value of the publishing process
# This is in the range 0-20
#   0 : Standard priority thread
#   20: Minimum priority thread
# the higher this value is the lower the priority of the publishing thread
# you should set this low so that publishing the site doesn't affect the
# responsiveness of your site.
publish_niceness 18

back do
  port 3001
end

front do
  port 3002
end
