#!/usr/bin/env python3
"""Backport the applicable runtime portion of vLLM PR #57443 to R26.4."""

from __future__ import annotations

import os
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected one anchor, found {count}")
    return text.replace(old, new, 1)


root = Path(os.environ["VLLM_PACKAGE_ROOT"])
indexer_path = root / "v1/attention/backends/mla/indexer.py"
flash_path = root / "v1/attention/backends/mla/flashattn_mla_sparse.py"
speculator_path = root / "v1/worker/gpu/spec_decode/speculator.py"

indexer = indexer_path.read_text()
indexer = replace_once(
    indexer,
    "    decode: DeepSeekV32IndexerDecodeMetadata | None = None\n"
    "    prefill: DeepseekV32IndexerPrefillMetadata | None = None\n",
    "    decode: DeepSeekV32IndexerDecodeMetadata | None = None\n"
    "    prefill: DeepseekV32IndexerPrefillMetadata | None = None\n"
    "    positions: torch.Tensor | None = None\n",
    "indexer metadata positions",
)
indexer = replace_once(
    indexer,
    "        self.dcp_world_size = parallel_config.decode_context_parallel_size\n"
    "        self.dcp_rank = get_dcp_group().rank_in_group if self.dcp_world_size > 1 else 0\n",
    "        self.dcp_world_size = parallel_config.decode_context_parallel_size\n"
    "        self.supports_draft_decode_metadata_update = self.dcp_world_size == 1\n"
    "        self.dcp_rank = get_dcp_group().rank_in_group if self.dcp_world_size > 1 else 0\n",
    "indexer fused decode capability",
)
indexer = replace_once(
    indexer,
    "            prefill=prefill_metadata,\n"
    "            decode=decode_metadata,\n"
    "        )\n\n"
    "        return attn_metadata\n\n\n"
    "def build_prefill_chunk_metadata(\n",
    "            prefill=prefill_metadata,\n"
    "            decode=decode_metadata,\n"
    "            positions=common_attn_metadata.positions,\n"
    "        )\n\n"
    "        return attn_metadata\n\n"
    "    def update_draft_decode_metadata(\n"
    "        self,\n"
    "        metadata: DeepseekV32IndexerMetadata,\n"
    "    ) -> None:\n"
    "        decode = metadata.decode\n"
    "        if decode is None or metadata.num_decode_tokens == 0:\n"
    "            return\n\n"
    "        assert metadata.num_prefills == 0\n"
    "        assert metadata.num_decodes == metadata.num_decode_tokens\n"
    "        assert decode.seq_lens.numel() == metadata.num_decode_tokens\n"
    "        assert self.dcp_world_size == 1\n\n"
    "        if self.compress_ratio > 1:\n"
    "            get_compressed_slot_mapping(\n"
    "                metadata.num_decode_tokens,\n"
    "                self.arange_buffer[: metadata.num_decode_tokens + 1],\n"
    "                metadata.seq_lens,\n"
    "                decode.block_table,\n"
    "                self.kv_cache_spec.num_states,\n"
    "                self.compress_ratio,\n"
    "                out=metadata.slot_mapping,\n"
    "            )\n"
    "            torch.div(\n"
    "                metadata.seq_lens,\n"
    "                self.compress_ratio,\n"
    "                rounding_mode=\"floor\",\n"
    "                out=decode.seq_lens.view(-1),\n"
    "            )\n"
    "        else:\n"
    "            decode.seq_lens.view(-1).copy_(metadata.seq_lens)\n"
    "        decode.decode_lens.fill_(1)\n\n"
    "        if current_platform.is_cuda() and has_deep_gemm():\n"
    "            schedule_metadata = get_paged_mqa_logits_metadata(\n"
    "                decode.seq_lens,\n"
    "                self.kv_cache_spec.num_states,\n"
    "                self.num_sms,\n"
    "                indices=decode.indices,\n"
    "            )\n"
    "            assert schedule_metadata.shape == decode.schedule_metadata.shape\n"
    "            decode.schedule_metadata.copy_(schedule_metadata)\n\n\n"
    "def build_prefill_chunk_metadata(\n",
    "indexer fused decode updater",
)
indexer_path.write_text(indexer)

flash = flash_path.read_text()
flash = replace_once(
    flash,
    "        self._init_reorder_batch_threshold(threshold, supports_spec_as_decode=True)\n\n\n"
    "class FlashAttnMLASparseImpl",
    "        self._init_reorder_batch_threshold(threshold, supports_spec_as_decode=True)\n"
    "        self.supports_draft_decode_metadata_update = self.dcp_world_size == 1\n\n"
    "    def update_draft_decode_metadata(\n"
    "        self, _metadata: FlashAttnMLASparseMetadata\n"
    "    ) -> None:\n"
    "        pass\n\n\n"
    "class FlashAttnMLASparseImpl",
    "FlashAttention sparse fused decode capability",
)
flash_path.write_text(flash)

speculator = speculator_path.read_text()
speculator = replace_once(
    speculator,
    "            causal=causal,\n"
    "            seq_lens_cpu_upper_bound=draft_seq_lens_cpu_upper_bound,\n"
    "            model_specific_attn_metadata=model_specific_attn_metadata,\n",
    "            causal=causal,\n"
    "            seq_lens_cpu_upper_bound=draft_seq_lens_cpu_upper_bound,\n"
    "            positions=self.input_buffers.positions[:num_tokens_padded],\n"
    "            model_specific_attn_metadata=model_specific_attn_metadata,\n",
    "draft positions propagation",
)
speculator_path.write_text(speculator)
