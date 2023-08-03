import fabric.main

if __name__ == '__main__':
    fabric.main.program.run('fab test --runTerraformOutput=false -s 0 --branch main --windowsBranch main --log-level DEBUG')