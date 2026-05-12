from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import ClassVar

from devnet.descriptor import Devnet


class AdapterError(Exception):
    pass


@dataclass(frozen=True)
class InputSpec:
    name: str
    description: str
    source: str  # devnet path (e.g. "op-deployer/state.json...") or "user-supplied"


@dataclass
class TaskFiles:
    config_toml: dict
    addresses_json: dict
    readme_context: dict = field(default_factory=dict)
    extra_env: dict[str, str] = field(default_factory=dict)


class Adapter(ABC):
    template_name: ClassVar[str]
    description: ClassVar[str]

    def __init_subclass__(cls, **kwargs):
        super().__init_subclass__(**kwargs)
        if getattr(cls, "template_name", None):
            register(cls)

    @abstractmethod
    def inputs(self) -> list[InputSpec]: ...

    @abstractmethod
    def build(self, devnet: Devnet, overrides: dict[str, str]) -> TaskFiles: ...

    def verify(
        self,
        devnet: Devnet,
        task_files: TaskFiles,
        rpc_url: str,
    ) -> None:
        """Optional onchain sanity checks.

        Called by the CLI after :meth:`build` has produced ``task_files``,
        unless the user passed ``--offline``. The default implementation is a
        no-op. Adapters that touch onchain state (e.g. OPCM upgrades, which
        must point at an OPCM whose ``version()`` matches the template) should
        override this and raise :class:`AdapterError` on mismatch.
        """
        return None

    def validate_offline(self, devnet: Devnet, task_files: TaskFiles) -> None:
        """Optional validation when the user skips onchain checks.

        Adapters that normally fill fields during :meth:`verify` should override
        this to prevent writing unresolved placeholders under ``--offline``.
        """
        return None


ADAPTERS: dict[str, Adapter] = {}


def register(cls: type[Adapter]) -> None:
    name = cls.template_name
    if name in ADAPTERS and type(ADAPTERS[name]) is not cls:
        raise AdapterError(
            f"Duplicate adapter registration for template '{name}': "
            f"{type(ADAPTERS[name]).__module__} vs {cls.__module__}"
        )
    ADAPTERS[name] = cls()
