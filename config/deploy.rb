set :application, "lccplacement"
set :repository,  "svn+ssh://math.lanecc.edu/Users/bill/SVNrep/lccplacement/trunk"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/Library/WebServer/#{application}"

set :runner, nil

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

default_run_options[:pty] = true

role :app, "math.lanecc.edu"
role :web, "math.lanecc.edu"
role :db,  "math.lanecc.edu", :primary => true