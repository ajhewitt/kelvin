# The admin screens go by the bar's name, in the board's colors (app/assets/stylesheets/admin.css)
Madmin.site_name = "The Ludlow Park"

# After Madmin's own stylesheet, which its engine adds once the app's initializers have run
Rails.application.config.after_initialize do
  Madmin.stylesheets << "admin"
end
