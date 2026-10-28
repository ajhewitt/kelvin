# The admin screens go by the bar's name, in the board's colors (app/assets/stylesheets/admin.css)
Madmin.site_name = "The Ludlow Park"

# After Madmin's own stylesheet, which its engine adds once the app's initializers have run
Rails.application.config.after_initialize do
  Madmin.stylesheets << "admin"
end

# The sidebar's sections, in order; resources join one with `menu parent:`
Madmin.menu.before_render do
  add label: "Tap list", position: 1
  add label: "Refrigeration", position: 2
  add label: "Logs", position: 3
end
