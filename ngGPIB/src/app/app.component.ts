import { Component } from '@angular/core';
interface TestObject {
  name: string;
  value: number;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  websitename = "GPIB";
  title = 'ngGPIB';

  objArray: TestObject[];
  selectedObject:TestObject;
  constructor() {

    this.objArray = [{ name: 'foo', value: 1 }, { name: 'bar', value: 2 }];
    this.selectedObject = this.objArray[1];
  }
  updateSelectedValue( e, o ) {
    console.log( "updateSelectedValue: ", e, o )
  }
}
