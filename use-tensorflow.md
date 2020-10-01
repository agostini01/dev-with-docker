# Compiling TensorFlow

1. Clone TensorFlow project at any location
   - `git clone https://github.com/tensorflow/tensorflow.git`
1. Run the `./start-docker.sh` from inside tensorflow folder or from a folder
    that contains the tensorflow project
   - `start-docker.sh` will take you to the container
   - The folder from where you called `start-docker.sh` is mounted to
    `/working_dir` 
1. Enter tensorflow project and compile tensorflow binaries

```
# Compile important tensorflow binaries
cd tensorflow
bazel build //tensorflow/compiler/mlir/hlo:mlir-hlo-opt
bazel build //tensorflow/compiler/mlir/hlo:tf-mlir-translate
bazel build //tensorflow/compiler/mlir/hlo:tf-opt
```