import fabric.main

if __name__ == '__main__':
    fabric.main.program.run('fab test --runTerraformOutput=true -s 0 --log-level DEBUG')