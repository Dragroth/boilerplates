.PHONY: rocky-9 debian-12 arch ubuntu-2204 all

all: rocky-99 debian-12 arch ubuntu-2204
rocky-9:
	packer init rocky-9
	packer build -var-file rocky-9/variables.pkrvars.hcl rocky-9/

ubuntu-2204:
	packer init ubuntu-2204
	packer build -var-file ubuntu-2204/variables.pkrvars.hcl ubuntu-2204

debian-12:
	packer init debian-12
	packer build -var-file debian-12/variables.pkrvars.hcl debian-12

arch:
	packer init arch
	packer build -var-file=arch/variables.pkrvars.hcl arch/arch.pkr.hcl