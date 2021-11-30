# In test mode we compile and test all locales
import Config

config :ex_unit,
  case_load_timeout: 220_000,
  timeout: 120_000

config :ex_cldr,
  default_backend: TestBackend.Cldr