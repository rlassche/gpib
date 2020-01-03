
// Collect the typeahead form data
export class taFieldsForm {
    public DEVICE_ID?: string;
    constructor(DEVICE_ID: string) {
      this.DEVICE_ID = '';
    }
}
export class typeaheadKeys {
    public keyColumnName: string;     /* like: artist_id */
    public keyValue: number;          /* like: 1 */
    public typeaheadColumnName: string;     /* like: artist */
    public typeaheadValue: string; /* Like: Abba */
    constructor(keyColumnName, keyValue, typeaheadColumnName, typeaheadValue) {
      this.keyColumnName = '';
      this.keyValue = 0,
      this.typeaheadColumnName = ''
      this.typeaheadValue = ''
    }
  }

  export class GPIB_DEVICE {
    public DESCRIPTION:string;
    public DEVICE_ID:string;
    public ADDDATE:string;
    public EOS_MODE:number;
    public MINOR:number;
    public MODDATE:string;
    public PAD:number;
    public SAD:number;
    public SEND_EOI:number;
    public TIMEOUT:number;
  }

  export class DEVICE_FUNCTION {
    public COMMAND_ID:string;
    public COMMAND_DESCRIPTION:string;
    public COMMAND_GROUP:string;
    public DEVICE_CODE:string;
    public ADDDATE:string;
    public MODDATE:string;
  }