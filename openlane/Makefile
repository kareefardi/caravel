# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

MAKEFLAGS=--warn-undefined-variables

# Env variables
OPENLANE_TAG ?= 2021.11.23_01.42.34
OPENLANE_IMAGE_NAME ?= efabless/openlane:$(OPENLANE_TAG)

# configuration varaibles
threads = 16

# target variables for easier interfaces
blocks = $(shell find * -maxdepth 0 -type d)
regression-target = $(blocks:%=%-regression)
clean-target = $(blocks:%=clean-%)

# aliases to avoid code duplication
openlane_basic_command = "cd $$(realpath $(PWD)/../openlane) && flow.tcl -design ./$* -save_path $$(realpath ..) -save -overwrite"
openlane_interactive_command = "cd $$(realpath $(PWD)/../openlane) && flow.tcl -it -file $$(realpath./$*/interactive.tcl)"
openlane_regression_command = "python3 run_designs.py --regression $(PWD)/$*/regression.config --threads $(threads) $(PWD)/$*"
define docker_run
		docker run -it -v $(OPENLANE_ROOT):/openlane \
		-v $(PDK_ROOT):$(PDK_ROOT) \
		-v $(PWD)/..:$(PWD)/.. \
		-v $(CARAVEL_ROOT):$(CARAVEL_ROOT) \
		-v $(MGMT_AREA_ROOT):$(MGMT_AREA_ROOT) \
		-e PDK_ROOT=$(PDK_ROOT) \
		-e CARAVEL_ROOT=$(CARAVEL_ROOT) \
		-u $(shell id -u $(USER)):$(shell id -g $(USER)) \
		$(OPENLANE_IMAGE_NAME)
endef
define print_exports
	@echo "pdk root: $(PDK_ROOT)"
	@echo "openlane image: $(OPENLANE_IMAGE_NAME)"
	@echo "openlane root: $(OPENLANE_ROOT)"
endef

all: $(blocks)

./%/regression.config:
	$(error file $@ not found. please provide one)

./%/config.tcl:
	$(error file $@ not found. please provide one)

.PHONY: $(regression-target)
$(regression-target):  %-regression : ./%/regression.config
ifeq ($(OPENLANE_ROOT),)
	@echo "Please export OPENLANE_ROOT"
	@exit 1
endif
		$(call docker_run) sh -c $(openlane_regression_command)

.PHONY: $(blocks)
$(blocks) : % : ./%/config.tcl
ifeq ($(PDK_ROOT),)
	$(error Please export PDK_ROOT)
endif
	$(call print_exports)
	@sleep 5
	@echo "###############################################"

	@if [ -f ./$*/interactive.tcl ]; then\
		$(call docker_run) sh -c $(openlane_interactive_command);\
	else\
		$(call docker_run) sh -c $(openlane_basic_command);\
	fi
	mkdir -p ../signoff/$*/
	# ignoring signoff directory for now
	# the bellow commands aren't executing
	# cp $*/runs/$*/OPENLANE_VERSION ../signoff/$*/
	# cp $*/runs/$*/PDK_SOURCES ../signoff/$*/
	# cp $*/runs/$*/reports/final_summary_report.csv ../signoff/$*/
	$(call print_exports)

.PHONY: openlane
openlane: $(OPENLANE_ROOT)
ifeq ($(OPENLANE_ROOT),)
	$(error Please export OPENLANE_ROOT)
endif

$(OPENLANE_ROOT):
	git clone https://github.com/The-OpenROAD-Project/OpenLane --branch=$(OPENLANE_TAG) --depth=1 $(OPENLANE_ROOT) && \
		cd $(OPENLANE_ROOT) && \
		export IMAGE_NAME=efabless/openlane:$(OPENLANE_TAG) && \
		make openlane

clean:
	@echo "Use clean-all to clean everything :)"

clean-all: $(clean-target)

$(clean-target): clean-% :
	rm -rf runs/$*
	rm -rf ../gds/$**
	rm -rf ../mag/$**
	rm -rf ../lef/$**
