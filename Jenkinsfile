def makeDocker(dockerImage, makeOp) {
    // Testargs are passed on and ignores TestRead_PathNoPermission because root (inside container) can read all..<
    env.XC_ARCH = "386 amd64"
    env.XC_OS = "linux darwin windows"
    // TF_DEV is set to true to avoid build.sh to try to zip stuff (zip is not available in the docker image)
    sh """
        docker run \
            --rm \
            -u \
            -i \
            -e TF_DEV=true \
            -e XC_ARCH="\$XC_ARCH}" \
            -e XC_OS="\$XC_OS}" \
            -v \$WORKSPACE:/go/src/github.com/hashicorp/terraform \
            -w /go/src/github.com/hashicorp/terraform \
            ${dockerImage} make ${makeOp}
    """
}

def artifactoryServer = Artifactory.server 'BAMBORA_ARTIFACTORY_CLOUD'

node("docker-concurrent") {
    stage "Checkout Code"
    checkout scm

    stage("Build terraform") {
        makeDocker("golang:1.7", "bin")
    }

    if (env.BRANCH_NAME == "master") {
        stage("Zip and upload to artifactory") {
            def tmpdir = sh script: 'mktemp -d', returnStdout: true
            tmpdir = tmpdir.trim()
            sh """
                cp -rvp pkg ${tmpdir}
                cd ${tmpdir}
                for PLATFORM in \$(find ./pkg -mindepth 1 -maxdepth 1 -type d); do
                    pushd \$PLATFORM >/dev/null 2>&1
                    zip ${env.WORKSPACE}/\$(basename \$PLATFORM).zip ./*
                    popd >/dev/null 2>&1
                done
                rm -rf ${tmpdir}
            """
            def uploadSpec = """{
                "files": [
                    {
                        "pattern": "*_*.zip",
                        "target": "binaries/terraform/"
                    }
                ]
            }"""
            artifactoryServer.upload(uploadSpec)
        }

        stage("Build docker image") {
            sh "docker build -t bambora-dkr.jfrog.io/terraform:${env.BRANCH_NAME} ."
        }

        stage("Push docker image") {
            sh "docker push bambora-dkr.jfrog.io/terraform:${env.BRANCH_NAME}"
        }
    }
}
