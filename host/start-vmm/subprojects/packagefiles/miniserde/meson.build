# SPDX-FileCopyrightText: 2023-2024 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

project('miniserde', 'rust', version : '0.1.38',
  default_options : ['build.rust_std=2021', 'rust_std=2021'])

quote_dep = dependency('quote-rs', native : true)
syn_dep = dependency('syn-rs', native : true)

mini_internal = shared_library('mini_internal', 'derive/src/lib.rs',
  dependencies : [quote_dep, syn_dep],
  native : true,
  rust_crate_type : 'proc-macro')

itoa_dep = dependency('itoa-rs')
ryu_dep = dependency('ryu-rs')

miniserde_rust_args = []
if not get_option('unwind')
  miniserde_rust_args += ['-C', 'panic=abort']
endif

miniserde = static_library('miniserde', 'src/lib.rs',
  dependencies : [itoa_dep, ryu_dep],
  link_with : mini_internal,
  rust_args : miniserde_rust_args,
  rust_crate_type : 'rlib')

miniserde_dep = declare_dependency(
  dependencies : [itoa_dep, ryu_dep],
  link_with : miniserde)

meson.override_dependency('miniserde-rs', miniserde_dep)
