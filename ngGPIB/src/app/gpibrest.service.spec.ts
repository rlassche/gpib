import { TestBed } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { GpibrestService } from './gpibrest.service';

describe('GpibrestService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: GpibrestService = TestBed.get(GpibrestService);
    expect(service).toBeTruthy();
  });
});
