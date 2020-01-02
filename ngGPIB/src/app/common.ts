
// Collect the typeahead form data
export class taFieldsForm {
    public gpib_device?: string;
    constructor(gpib_device: string) {
      this.gpib_device = '';
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
