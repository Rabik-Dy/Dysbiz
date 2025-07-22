from odoo import models, fields, api
from odoo.exceptions import ValidationError

class HrLeave(models.Model):
    _inherit = 'hr.leave'

    second_approver_id = fields.Many2one(
        'hr.employee',
        string='Second Approver (VP)'
    )

    # Extend the state field with 'validate1'
    state = fields.Selection(
        selection_add=[('validate1', 'First Level Approved')]
    )

    @api.model
    def create(self, vals):
        record = super().create(vals)
        if record.employee_id and record.employee_id.parent_id:
            template = self.env.ref('custom_timeoff_approval.email_template_to_first_approver', raise_if_not_found=False)
            if template:
                template.send_mail(record.id, force_send=True)
        return record

    def action_approve(self):
        current_employee = self.env.user.employee_id
        if not current_employee:
            raise ValidationError("Your user is not linked to an employee.")

        for leave in self:
            if leave.state == 'confirm':
                if leave.second_approver_id and current_employee.id == leave.second_approver_id.id:
                    raise ValidationError("Second approver cannot approve at first level.")

                if leave.employee_id and leave.employee_id.parent_id and current_employee.id == leave.employee_id.parent_id.id:
                    if leave.second_approver_id and current_employee.id == leave.second_approver_id.id:
                        raise ValidationError("First approver cannot also be second approver.")
                    leave.write({'state': 'validate1'})
                    template = self.env.ref('custom_timeoff_approval.email_template_to_second_approver', raise_if_not_found=False)
                    if template:
                        template.send_mail(leave.id, force_send=True)
                else:
                    raise ValidationError("You are not allowed to approve at first level.")

            elif leave.state == 'validate1':
                if leave.employee_id and leave.employee_id.parent_id and current_employee.id == leave.employee_id.parent_id.id:
                    raise ValidationError("First approver cannot approve at second level.")

                if leave.second_approver_id and current_employee.id == leave.second_approver_id.id:
                    leave.write({'state': 'validate'})
                    template = self.env.ref('custom_timeoff_approval.email_template_to_employee', raise_if_not_found=False)
                    if template:
                        template.send_mail(leave.id, force_send=True)
                else:
                    raise ValidationError("You are not allowed to approve at second level.")
