{
    'name': 'Custom Time Off 2-Level Approval with Emails',
    'version': '1.0',
    'summary': 'Adds second approver and 2-level approval email notifications',
    'category': 'Human Resources',
    'author': 'Your Name',
    'depends': ['hr_holidays', 'mail'],
    'data': [
        'views/hr_leave_view.xml',
        'data/email_template.xml',
        'data/automated_actions.xml',
    ],
    'installable': True,
    'application': False,
}
