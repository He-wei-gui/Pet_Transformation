import { describe, it, expect } from '@ohos/hypium';
import { DateUtil } from '../main/ets/utils/DateUtil';
import { ScheduleService } from '../main/ets/service/ScheduleService';
import { Validator, ValidationResult } from '../main/ets/utils/Validator';

export default function localUnitTest() {
  describe('DateUtil', () => {
    it('format_padsZero', 0, () => {
      expect(DateUtil.format(new Date(2024, 0, 5))).assertEqual('2024-01-05');
    });
    it('addDays_crossMonth', 0, () => {
      expect(DateUtil.addDays('2024-01-30', 2)).assertEqual('2024-02-01');
    });
    it('addDays_negative', 0, () => {
      expect(DateUtil.addDays('2024-03-01', -1)).assertEqual('2024-02-29');
    });
    it('diffDays', 0, () => {
      expect(DateUtil.diffDays('2024-01-01', '2024-01-10')).assertEqual(9);
    });
    it('isValid_rejectsBadDate', 0, () => {
      expect(DateUtil.isValid('2024-02-30')).assertFalse();
      expect(DateUtil.isValid('2024-01-15')).assertTrue();
    });
    it('monthKey', 0, () => {
      expect(DateUtil.monthKey('2024-03-15')).assertEqual('2024-03');
    });
  });

  describe('ScheduleService', () => {
    it('nextFeedDate_addsInterval', 0, () => {
      expect(ScheduleService.nextFeedDate('2024-05-10', 3)).assertEqual('2024-05-13');
    });
    it('nextSubstrateDate_addsInterval', 0, () => {
      expect(ScheduleService.nextSubstrateDate('2024-05-10', 30)).assertEqual('2024-06-09');
    });
  });

  describe('Validator', () => {
    it('username_required', 0, () => {
      const r: ValidationResult = Validator.username('');
      expect(r.valid).assertFalse();
      expect(r.messageKey).assertEqual('err_username_required');
    });
    it('username_format', 0, () => {
      expect(Validator.username('ab').valid).assertFalse();
      expect(Validator.username('abc').valid).assertTrue();
      expect(Validator.username('good_name1').valid).assertTrue();
    });
    it('password_min', 0, () => {
      expect(Validator.password('123').valid).assertFalse();
      expect(Validator.password('123456').valid).assertTrue();
    });
    it('passwordMatch', 0, () => {
      expect(Validator.passwordMatch('a', 'b').valid).assertFalse();
      expect(Validator.passwordMatch('same', 'same').valid).assertTrue();
    });
    it('intervalDays_range', 0, () => {
      expect(Validator.intervalDays('0').valid).assertFalse();
      expect(Validator.intervalDays('366').valid).assertFalse();
      expect(Validator.intervalDays('3').valid).assertTrue();
    });
    it('positiveNumber', 0, () => {
      expect(Validator.positiveNumber('-1').valid).assertFalse();
      expect(Validator.positiveNumber('0').valid).assertFalse();
      expect(Validator.positiveNumber('5.5').valid).assertTrue();
    });
  });
}
