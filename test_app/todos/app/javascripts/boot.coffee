# This file require's your application and initializes it.
# This code is called in development and integration test mode. It is
# not called during unit tests. This is to prevent your app from booting
# and paying costly initialization costs when you should only be testing
# small parts in isolation.
# 
# Here's an example:
#
#   require('todos/app')
#   Todos.boot()
#
# Your boot code begins here...

require 'todos/app'

Todos.createApp()
Todos.app.initialize()