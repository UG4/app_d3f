# d3f++ app

d3f++ is the distributed density driven flow library. 

It is provided as an extension for the UG4 toolbox. 

## Installation

First, obtain sources, e.g. using ughub:

```bash
mkdir d3f-ug4
cd d3f-ug4
ughub init
ughub install d3f_plusplus_app
ughub git submodule init 
ughub git submodule update --init 
```

Second, compile using cmake:
```bash
cmake -S . -B mybuild -DCMAKE_BUILD_TYPE=Release -DENABLE_ALL_PLUGINS=ON -DPARALLEL=ON -DJSON=ON -DUSE_JSON=ON -DJSONToolkit=ON
cmake --build mybuild --parallel
```

## Usage

After install, execute scripts, e.g.,
```
ugshell -ex apps/d3f_plusplus_app/henry/henry.lua
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

A list of contributors is available [here](CONTRIBUTORS.md)

## License

The d3f extensions are provided under [EUPL v1.2](LICENSES/EUPL-v1.2.txt).

UG4 is provided under [LGPL v3](https://github.com/UG4/ugcore/blob/master/LICENSE).