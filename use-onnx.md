# Using ONNX-mlir

Project available at: https://github.com/onnx/onnx-mlir

## Build Steps:

Clone necessary projects:

```bash
mkdir onnx
cd onnx   # This will hold all proj the dependencies
git clone https://github.com/llvm/llvm-project.git
cd llvm-project && git checkout 91671e13efbc5dbd17b832d7973401350d0a6ee6 && cd ..
git clone --recursive https://github.com/onnx/onnx-mlir.git
cd onnx-mlir && git checkout --recurse-submodules 75930ffbcf14cfbaccd8417c47c3598f56342926 && cd ..
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf && git checkout --recurse-submodules d16bf914bc5ba569d2b70376051d15f68ce4322d && cd ..
```

From this `onnx` folder, execute `start-docker.sh`.

**All the commands below are executed in the docker container.**

Build mlir:
```bash
mkdir llvm-project/build
cd /working_dir/llvm-project/build
cmake -G Ninja ../llvm \
   -DLLVM_ENABLE_PROJECTS=mlir \
   -DLLVM_BUILD_EXAMPLES=ON \
   -DLLVM_TARGETS_TO_BUILD="host" \
   -DCMAKE_BUILD_TYPE=Release \
   -DLLVM_ENABLE_ASSERTIONS=ON \
   -DLLVM_ENABLE_RTTI=ON \
   -DPYTHON_EXECUTABLE=/usr/bin/python

cmake --build . --target -- ${MAKEFLAGS}
cmake --build . --target check-mlir
cd /working_dir
```

Build google's protobuf:

```bash
cd /working_dir/protobuf
git submodule update --init --recursive
./autogen.sh

 ./configure
 make -j12
 make check -j12
 sudo make install # if not changed in Dockerfile, password is: devpasswd
 sudo ldconfig # refresh shared library cache.

 cd /working_dir
 ```

Build ONNX:

```bash
# Export environment variables pointing to LLVM-Projects.
cd /working_dir
export LLVM_PROJ_SRC=$(pwd)/llvm-project/
export LLVM_PROJ_BUILD=$(pwd)/llvm-project/build

mkdir onnx-mlir/build && cd onnx-mlir/build
cmake ..
cmake --build . -j12
```

Install onnx for python. This enables downloading several onnx models.

```bash
pip install onnx==1.7.0
```

## Test ONNX models

```
# This command runs ~1790 tests in 382s
cmake --build . --target check-onnx-backend
```

## Compile to LLVM IR

Compiling a simple `add` example to `mlir`.

```
./onnx-mlir --EmitONNXIR /working_dir/onnx-mlir/third_party/onnx/onnx/backend/test/data/node/test_add/model.onn
./onnx-mlir --EmitLLVMIR /working_dir/onnx-mlir/third_party/onnx/onnx/backend/test/data/node/test_add/model.onnx.mlir

# Compile model to a shared library
./onnx-mlir --EmitLib /working_dir/onnx-mlir/third_party/onnx/onnx/backend/test/data/node/test_add/model.onnx.mlir
```

## Download and compile bigger models

The next subsections will guide you to:

1. download onnx models
1. compile to `onnx.mlir`,
1. compile to `llvm.mlir`, 
1. use `mlir-translate` to get a `.ll` file
1. use `clang-10` tools to "optimize" the `.ll` file and compile into `x86.asm`

### MNIST

```
mkdir /working_dir/examples/mnist
cd /working_dir/examples/mnist
wget https://github.com/onnx/models/blob/master/vision/classification/mnist/model/mnist-8.onnx?raw=true -O mnist.onnx
./onnx-mlir --EmitONNXIR /working_dir/examples/mnist/mnist.onnx
./onnx-mlir --EmitLLVMIR /working_dir/examples/mnist/mnist.onnx.mlir
/working_dir/llvm-project/build/bin/mlir-translate --mlir-to-llvmir /working_dir/examples/mnist/mnist.onnx.onnx.mlir -o /working_dir/examples/mnist/mnist.ll
```

From here, we have generated a `.ll` file that is flattened (no operations anymore)
and can be optimized by opt-10, llc-10 tools (earlier versions cannot parse
the generated `.ll`).
**Note:** Currently the docker container has opt-8, llc-8 installed on the
*PATH, which will not parse the file.

With the proper opt, llc versions. The `ll` code can be optimized with:

```bash
# This does not work with the current container which has clang-8
# These commands were executed outside of the container
clang-10.0.0-build/bin/opt ~/Development/onnx/examples/mnist/mnist.ll -O3 -S -o mnist-O3.ll
clang-10.0.0-build/bin/llc ~/Development/onnx/examples/mnist/mnist-O3.ll  # Generates .s assembly file
```

### RESNET-50 V2 from onnx

```
mkdir /working_dir/examples/resent50-v2
cd /working_dir/examples/resent50-v2
wget https://s3.amazonaws.com/download.onnx/models/opset_9/resnet50.tar.gz
tar -xvf resnet50.tar.gz # will extract a model.onnx file

# This will take a couple of minutes to run
./onnx-mlir --EmitONNXIR /working_dir/examples/resnet50-onnx/resnet50/model.onnx
./onnx-mlir --EmitLLVMIR /working_dir/examples/resnet50-onnx/resnet50/model.onnx.mlir
```

With the proper opt, llc versions. The `ll` code can be optimized with:

```bash
# This does not work with the current container which has clang-8
# These commands were executed outside of the container
clang-10.0.0-build/bin/opt ~/Development/onnx/examples//mnist.ll -O3 -S -o mnist-O3.ll
clang-10.0.0-build/bin/llc ~/Development/onnx/examples/mnist/mnist-O3.ll  # Generates .s assembly file
```


### RESNET-50 V1.5 from pytorch

Currently not working.

This exemple downloads a ResNet50 v1.5 model and convert it to onnx.
This issue claims that pytorch implementation of resent is v1.5.

* https://github.com/pytorch/vision/issues/1266

To download the model:
```
mkdir /working_dir/examples/mnist
cd /working_dir/examples/mnist

# Model will be downloaded from here
# https://github.com/pytorch/vision/blob/master/torchvision/models/resnet.py
pip install torch torchvision
pip install onnx==1.7.0
python convert-to-onnx.py
```

Compiling this model currently breaks.

```
./onnx-mlir --EmitONNXIR /working_dir/examples/resnet-1-5/resnet-1-5.onnx
```

Error:
```
onnx-mlir: /working_dir/llvm-project/mlir/include/mlir/IR/Types.h:308: U mlir::Type::cast() const [U = mlir::MemRefType]: Assertion `isa<U>()' failed.
Aborted (core dumped)
```

### RESNET v2 from onnx zoo

Currently not working.

To download:
```bash
mkdir /working_dir/examples/resent50-v2
cd /working_dir/examples/resent50-v2
wget https://github.com/onnx/models/blob/master/vision/classification/resnet/model/resnet50-v2-7.onnx?raw=true -O resnet50-v2.onnx
```

Compiling this model currently breaks at the first step.
```bash
./onnx-mlir --EmitONNXIR /working_dir/examples/resnet50-v2/resnet50-v2.onnx
```

Error:
```
error: unable to infer shape of operation without shape inference interface
error: Input data tensor not ranked
error: shape inference failed
error: Input tensor(s) not ranked
error: shape inference failed
error: Shape inference failed, 3 operations couldn't be inferred
```

## Run FileCheck tests

```
export LIT_OPS=v
cmake --build . --target check-onnx-lit
```
For the current commit (`d16bf914bc5ba569d2b70376051d15f68ce4322d`), not all
passes succeed:

```
[100%] Running the ONNX MLIR regression tests
-- Testing: 31 tests, 31 workers --
UNSUPPORTED: Open Neural Network Frontend :: krnl/pack_krnl_constants_be/pack_krnl_constants.mlir (1 of 31)
PASS: Open Neural Network Frontend :: conversion/krnl_to_affine.mlir (2 of 31)
...
PASS: Open Neural Network Frontend :: onnx/onnx_shape_inference.mlir (31 of 31)
********************
Failed Tests (1):
  Open Neural Network Frontend :: onnx/onnx_krnl_global_elision.mlir


Testing Time: 0.55s
  Unsupported:  1
  Passed     : 29
  Failed     :  1
test/mlir/CMakeFiles/check-onnx-lit.dir/build.make:76: recipe for target 'test/mlir/CMakeFiles/check-onnx-lit' failed
make[3]: *** [test/mlir/CMakeFiles/check-onnx-lit] Error 1
CMakeFiles/Makefile2:4451: recipe for target 'test/mlir/CMakeFiles/check-onnx-lit.dir/all' failed
make[2]: *** [test/mlir/CMakeFiles/check-onnx-lit.dir/all] Error 2
CMakeFiles/Makefile2:4458: recipe for target 'test/mlir/CMakeFiles/check-onnx-lit.dir/rule' failed
make[1]: *** [test/mlir/CMakeFiles/check-onnx-lit.dir/rule] Error 2
Makefile:1793: recipe for target 'check-onnx-lit' failed
make: *** [check-onnx-lit] Error 2
```


### Plot network to svg

Requires:
```
apt install graphviz
pip install pydot

# FILENAME represents a path to a onnx model WITHOUT the .onnx extension
FILENAME=resnet50-onnx/resnet50/model bash -c 'python /working_dir/onnx-mlir/third_party/onnx/onnx/tools/net_drawer.py --input ${FILENAME}.onnx --output ${FILENAME}.dot --embed_docstring && dot -Tsvg ${FILENAME}.dot -o ${FILENAME}.svg'
```