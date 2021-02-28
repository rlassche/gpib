import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import {DevicesComponent} from './gpib/devices.component';
import {HomeComponent} from './home/home.component';


const routes: Routes = [
  { path: 'devices', component: DevicesComponent },
  { path: 'home', component: HomeComponent },
];

@NgModule({
  imports: [RouterModule.forRoot(routes, { relativeLinkResolution: 'legacy' })],
  exports: [RouterModule]
})
export class AppRoutingModule { }
