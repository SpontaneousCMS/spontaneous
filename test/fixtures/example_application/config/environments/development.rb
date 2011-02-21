
over_ridden :development_value

back do
  port 9001
end

front do
  port 9002
end

# can be one of :threaded, :immediate or :fire_and_forget
publishing_method :threaded

publishing_delay 10

