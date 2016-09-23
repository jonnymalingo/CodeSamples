using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class InstructionManager : MonoBehaviour {

	public Instruction currentInstruction;
	Instruction[] instructions;
	GameObject textObject;
	// Use this for initialization
	void Start () {

		this.textObject = GameObject.Find ("InstructionText");

		GameObject[] inst = GameObject.FindGameObjectsWithTag ("Instruction");
		this.instructions = new Instruction[inst.Length];
		foreach (GameObject gameObject in inst) {

			foreach (Transform child in gameObject.transform.parent)
			{
				child.renderer.enabled = false;
			}

			Instruction instruction = (Instruction)gameObject.GetComponent(typeof(Instruction));
			this.instructions[instruction.index] = instruction;
		}
		this.currentInstruction = this.instructionWithIndex (0);
		this.startInstruction ();
	}
	
	// Update is called once per frame
	void Update () {

	}

	void startInstruction () {
		Instruction instruction = (Instruction)this.currentInstruction;
		Text instructionText = this.textObject.GetComponent<Text>();
		instructionText.text = instruction.text;
		foreach (Transform child in this.currentInstruction.gameObject.transform.parent)
		{
			child.renderer.enabled = true;
		}
	}

	public void completeInstruction () {
		this.currentInstruction.isCompleted = true;
		foreach (Transform child in this.currentInstruction.gameObject.transform.parent)
		{
			child.renderer.enabled = false;
		}
		Instruction next = this.instructionWithIndex (this.currentInstruction.index + 1);
		if (next) {
			this.currentInstruction = next;
			this.startInstruction ();
		} else {
			Text instructionText = this.textObject.GetComponent<Text>();
			instructionText.text = "Stage Complete!";
			//TODO: Handle stage complete
		}
	}

	Instruction instructionWithIndex (int index) {
		foreach (Instruction instruction in this.instructions) {

			if (instruction.index == index) {
				return instruction;
			}
		}
		return null;
	}
}
