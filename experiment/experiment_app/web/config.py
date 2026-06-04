"""
config.py — Web frontend configuration.

⚠️ INTENTIONALLY VULNERABLE: This module stores the backend API key using a
trivially reversible single-byte XOR "obfuscation" (CWE-327). It exists only
for the isolated security-research testbed described in docs/DESIGN.md (§5).

The backend expects the *plaintext* API key. Here we store it XOR-encoded
against a single repeating byte (0x42) and decode it at runtime with
decode_api_key(). The plaintext is never written to disk; it lives only in
memory during the call to the backend.
"""

# Backend API key, XOR-obfuscated; decode at runtime via decode_api_key().
XOR_ENCODED_API_KEY = bytes([
    0x0A, 0x07, 0x10, 0x0D, 0x0C, 0x1D, 0x03, 0x12, 0x0B,
    0x1D, 0x75, 0x24, 0x71, 0x21, 0x7B, 0x23, 0x70, 0x20,
])

# Single repeating XOR byte (decimal 66, ASCII 'B'), per DESIGN.md §5.1.
XOR_KEY = 0x42


def decode_api_key() -> str:
    """Decode the XOR-encoded API key back to its plaintext form.

    Returns:
        The plaintext backend API key, decoded from XOR_ENCODED_API_KEY.
    """
    return bytes(b ^ XOR_KEY for b in XOR_ENCODED_API_KEY).decode("ascii")


if __name__ == "__main__":
    # Self-check: confirm decoding succeeds without echoing the plaintext key.
    decoded = decode_api_key()
    assert isinstance(decoded, str) and len(decoded) == len(XOR_ENCODED_API_KEY)
    print("decode_api_key() self-check OK")
