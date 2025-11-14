# Common instructions when creating new test cases
  - Before creating a new test case, read all files in the directory to understand what the existing code does
  - By default use the GetCompactCompatiblePool function to get the MCP that we are going to test, unless the test can only be executed in the master pool or instructed otherwise
  - Use GetCurrentTestPolarionIDNumber() to get the test ID and call it only once
  - Use Generic MC template (default) when possible
  - Base64 encoded file configuration in MachineCOnfigs unless said otherwise
  - Use test number in file path and content and resources names
  - GetSortedNodesOrFail()[0] for first node selection
  - "OK!\n" logging after each step
  - Declare the variables in the "vars" section if possible
  - In error message try to log the full resources and using %s. Prefer logger.Infof("%s", node) to logger.Infof("%s",node.GetName())
  - Add AI-assisted comment
  - The initial state has to be always recovered when a test case finishes
  - Prioritize using the methods in the Resource struct instead of using oc.AsAdmin.Run
  - All files should be  `gofmt`-ed with `-s`
  - Use short concise comments to comment functions, one or two lines maximum

# MCO Test cases execution

MCO test cases can last up to 2 hours. Do not timeout the commands before under any circumstance.

# Git commit instructions

Do not add coauthor

Start commit messages with "MCO"

# Pull Requests instructions

Push the changes to sregidor remote and create the pull request to origin

If the test execution logs is available k

# Initial state recovery

If possible we can do like this  defer machineConfiguration.SetSpec(machineConfiguration.GetSpecOrFail())

# To verify files inside nodes

Use RemoteFile with the gomega checkers specially created for it
