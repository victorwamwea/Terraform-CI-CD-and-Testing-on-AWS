# Instructions: Create basic tests for Example Production Workload
# HINT: Make sure to run `terraform init` in this directory before running `terraform test`. Also, ensure you use constant values (e.g. string, number, bool, etc.) within your tests where at all possible or you may encounter errors.

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Global Testing Variables - Define variables to be used in all tests here. You can overwrite these varibles by definig an additional variables block within the 'run' block for your tests
variables {
  # - Test CodeCommit Repos -
  codecommit_repos = {
    # Test Module 1
    test_module_1 : {
      repository_name = "test-module-1"
      description     = "Test Module 1."
      default_branch  = "main"
      tags = {
        "ContentType" = "Test Module",
      }
    },
  }

# - Test CodeBuild Projects -
  codebuild_projects = {
    # Test Module 1
    tf_test_test_module_1 : {
      name        = "TerraformTest-test-module-1"
      description = "Test Module 1 - Terraform Test"
      build_spec  = <<-EOF
        # Terraform Test
        version: 0.1
        phases:
          pre_build:
            commands:
              - terraform init
              - terraform validate

          build:
            commands:
              - terraform test
      EOF
    },
    chevkov_test_module_1 : {
      name        = "Checkov-test-module-1"
      description = "Test Module 1 - Checkov"
      build_spec  = <<-EOF
        # Checkov
        version: 0.1
        phases:
          pre_build:
            commands:
              - echo pre_build starting

          build:
            commands:
              - build starting
              - checkov -s -d ./ > checkov.result.txt

      EOF
    },
  }

  # - Test CodePipeline pipelines -
  codepipeline_pipelines = {
    #  Module Validation Pipelines
    # Terraform Module Validation Pipeline for 'test-module-1' Terraform Module
    tf_module_validation_test_module_1 : {
      name = "test-module-1"
      tags = {
        "Description" = "Test Module 1.",
      }

      stages = [
        # Clone from CodeCommit, store contents in  artifacts S3 Bucket
        {
          name = "Source"
          action = [
            {
              name     = "PullFromCodeCommit"
              category = "Source"
              owner    = "AWS"
              provider = "CodeCommit"
              version  = "1"
              configuration = {
                BranchName     = "main"
                RepositoryName = "test-module-1"
                PollForSourceChanges = false
              }
              input_artifacts = []
              #  Store the output of this stage as 'source_output_artifacts' in connected the Artifacts S3 Bucket
              output_artifacts = ["source_output_artifacts"]
              run_order        = 1
            },
          ]
        },

        # Run Terraform Test Framework
        {
          name = "Build_TF_Test"
          action = [
            {
              name     = "TerraformTest"
              category = "Build"
              owner    = "AWS"
              provider = "CodeBuild"
              version  = "1"
              configuration = {
                # Reference existing CodeBuild Project
                ProjectName = "TerraformTest-test-module-1"
              }
              # Use the 'source_output_artifacts' contents from the Artifacts S3 Bucket
              input_artifacts = ["source_output_artifacts"]
              # Store the output of this stage as 'build_tf_test_output_artifacts' in the connected Artifacts S3 Bucket
              output_artifacts = ["build_tf_test_output_artifacts"]

              run_order = 2
            },
          ]
        },

        # Run Checkov
        {
          name = "Build_Checkov"
          action = [
            {
              name     = "Checkov"
              category = "Build"
              owner    = "AWS"
              provider = "CodeBuild"
              version  = "1"
              configuration = {
                # Reference existing CodeBuild Project
                ProjectName = "Checkov-test-module-1"
              }
              # Use the 'source_output_artifacts' contents from the Artifacts S3 Bucket
              input_artifacts = ["source_output_artifacts"]
              # Store the output of this stage as 'build_checkov_output_artifacts' in the connected Artifacts S3 Bucket
              output_artifacts = ["build_checkov_output_artifacts"]

              run_order = 3
            },
          ]
        },
      ]
    }
  }


# Test Remote State Resources
  tf_remote_state_resource_configs = {
    # Custom Terraform Module Repo
    test_tf_remote_state_config_1 : {
      prefix = "test-tf-remote-state-config-1"
    },
  }

}

# - Unit Tests -
run "input_validation" {
  command = plan

  # Intentional invalid values to test functionality. These variables overwrite the above variables (helpful for testing).
  variables {
    # Intentional project_prefix that is longer than max of 40 characters (overwrite of above global variable)
    project_prefix = "this_is_a_project_prefix_and_it_is_over_40_characters_and_will_cause_a_failure"

    # CodeCommit - Intentional repository name that is longer than max of 40 characters
    codecommit_repos = {
      # Test Module 1 Repo
      test_module_1 : {

        repository_name = "this_is_a_repository_name_loger_than_100_characters_7rfD86rGwuqhF3TH9d3Y99r7vq6JZBZJkhw5h4eGEawBntZmvy"
        description     = "Test Module 1."
        default_branch  = "main"
        tags = {
          "ContentType" = "Test Module 1",

        },
      },
    }

    # CodeBuild - Intentional project name that is longer than max of 40 characters
    codebuild_projects = {
      # Test Module 1
      tf_test_test_module_1 : {
        name        = "this_is_a_project_name_and_it_is_longer_than_40_characters"
        description = "Test Module 1 - Terraform Test"
        build_spec  = <<-EOF
          # Terraform Test
          version: 0.1
          phases:
            pre_build:
              commands:
                - terraform init
                - terraform validate

            build:
              commands:
                - terraform test
        EOF
      },
    }

    # CodePipeline - Intentional pipeline name that is longer than max of 40 characters
    codepipeline_pipelines = {

      # Terraform Module Validation Pipeline for 'test-module-1' Terraform Module
      tf_module_validation_test_module_1 : {
        name = "this_is_a_pipeline_name_and_it_is_longer_than_40_characters_and_will_fail"
        tags = {
          "Description" = "Test Module 1.",

        }

        stages = [
          # Clone from CodeCommit, store contents in  artifacts S3 Bucket
          {
            name = "Source"
            action = [
              {
                name     = "PullFromCodeCommit"
                category = "Source"
                owner    = "AWS"
                provider = "CodeCommit"
                version  = "1"
                configuration = {
                  BranchName     = "main"
                  RepositoryName = "test-module-1"
                  PollForSourceChanges = false
                }
                input_artifacts = []
                #  Store the output of this stage as 'source_output_artifacts' in connected the Artifacts S3 Bucket
                output_artifacts = ["source_output_artifacts"]
                run_order        = 1
              },
            ]
          },

          # Run Terraform Test Framework
          {
            name = "Build_TF_Test"
            action = [
              {
                name     = "TerraformTest"
                category = "Build"
                owner    = "AWS"
                provider = "CodeBuild"
                version  = "1"
                configuration = {
                  # Reference existing CodeBuild Project
                  ProjectName = "TerraformTest-test-module-1"
                }
                # Use the 'source_output_artifacts' contents from the Artifacts S3 Bucket
                input_artifacts = ["source_output_artifacts"]
                # Store the output of this stage as 'build_tf_test_output_artifacts' in the connected Artifacts S3 Bucket
                output_artifacts = ["build_tf_test_output_artifacts"]

                run_order = 2
              },
            ]
          },

          # Run Checkov
          {
            name = "Build_Checkov"
            action = [
              {
                name     = "Checkov"
                category = "Build"
                owner    = "AWS"
                provider = "CodeBuild"
                version  = "1"
                configuration = {
                  # Reference existing CodeBuild Project
                  ProjectName = "Checkov-test-module-1"
                }
                # Use the 'source_output_artifacts' contents from the Artifacts S3 Bucket
                input_artifacts = ["source_output_artifacts"]
                # Store the output of this stage as 'build_checkov_output_artifacts' in the connected Artifacts S3 Bucket
                output_artifacts = ["build_checkov_output_artifacts"]

                run_order = 6
              },
            ]
          },
        ]
      },
    }

    # Terraform Remote State Resources - Intentional prefix that is longer than max of 40 characters
    tf_remote_state_resource_configs = {
      # Custom Terraform Module Repo
      test_tf_remote_state_config_1 : {
        prefix = "this_is_a_prefix_name_and_it_is_longer_than_40_characters_and_will_fail"
      },
    }
  }

  # Check for intentional failure of variables defined above. We expect these to fail since we intentionally provided values that do not conform to the validation rules defined in the module's variable.tf file.
  expect_failures = [
    var.project_prefix,
    var.codecommit_repos,
    var.codebuild_projects,
    var.codepipeline_pipelines,
    var.tf_remote_state_resource_configs,
  ]
}

# - End-to-end Tests -
run "e2e_test" {
  command = apply

  # Using global variables defined above since additional variables block is not defined here

  # Assertions
  # CodeCommit - Ensure repositories have correct names after creation
  assert {
    condition     = aws_codecommit_repository.codecommit["test_module_1"].repository_name == "test-module-1"
    error_message = "The CodeCommit Repo name (${aws_codecommit_repository.codecommit["test_module_1"].repository_name}) didn't match the expected value."
  }

  # CodeBuild - Ensure projects have correct names after creation
  assert {
    condition     = aws_codebuild_project.codebuild["tf_test_test_module_1"].name == "TerraformTest-test-module-1"
    error_message = "The CodeBuild Project name (${aws_codebuild_project.codebuild["tf_test_test_module_1"].name}) didn't match the expected value (TerraformTest-test-module-1)."
  }

  # CodePipeline - Ensure pipelines have correct names after creation
  assert {
    condition     = aws_codepipeline.codepipeline["tf_module_validation_test_module_1"].name == "test-module-1"
    error_message = "The CodePipeline pipeline name (${aws_codepipeline.codepipeline["tf_module_validation_test_module_1"].name}) didn't match the expected value (test-module-1)."
  }

  # S3 Remote State - Ensure S3 Remote State buckets have correct names after creation
  assert {
    condition     = startswith(aws_s3_bucket.tf_remote_state_s3_buckets["test_tf_remote_state_config_1"].id, "test-tf-remote-state-config-1")
    error_message = "The S3 Remote State Bucket name (${aws_s3_bucket.tf_remote_state_s3_buckets["test_tf_remote_state_config_1"].id}) did not start with the expected value (test-tf-remote-state-config-1)."
  }

  # DynamoDB Terraform State Lock Table - Ensure DynamoDB Terraform State Lock Tables have correct names after creation
  assert {
    condition     = startswith(aws_dynamodb_table.tf_remote_state_lock_tables["test_tf_remote_state_config_1"].id, "test-tf-remote-state-config-1")
    error_message = "The DynamoDB Terraform State Lock table name (${aws_dynamodb_table.tf_remote_state_lock_tables["test_tf_remote_state_config_1"].id}) did not start with the expected value (test-tf-remote-state-config-1)."
  }
}

