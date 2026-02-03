// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Eager load all controllers defined in the import map under controllers/**/*_controller
eagerLoadControllersFrom("controllers", application)
