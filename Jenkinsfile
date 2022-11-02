properties([
    parameters([
        string(defaultValue: 'apply', name: 'terraform_command'),
        string(defaultValue: 'us-east-1', name: 'region')
    ])
])
pipeline {
    agent any
    stages {
        /*
        stage ('Set Creds') {
            steps {
                
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'aws-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) 
                {
                    sh  script: """
                        #Set keys
                        aws configure set aws_access_key_id $USERNAME
                        aws configure set aws_secret_access_key $PASSWORD
                        """
                }
            }
        }
        */
        stage ('Run Static Analysis') {
            steps {
                sh  script: """
                    #Scan terraform code
                    sudo docker run --rm  -v \"\$(pwd):/\" tfsec/tfsec /infrastructure  || true
                    """
                }
            }

        stage ('Deploy Infrastructure') {
            steps {
                sh  script: """
                    terraform init
                    terraform ${terraform_command} -var="region=${region}" --auto-approve
                    """
            }
        }
        }
    }
}