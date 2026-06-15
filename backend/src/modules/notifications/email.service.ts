import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppConfig } from '../../config/configuration';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private config: ConfigService<AppConfig>) {
    const e = this.config.get('email', { infer: true });
    if (!e) return;
    const { smtpHost, smtpPort, smtpUser, smtpPass } = e;

    if (smtpHost && smtpUser && smtpPass) {
      this.transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort || 587,
        secure: (smtpPort || 587) === 465,
        auth: { user: smtpUser, pass: smtpPass },
      });
      this.logger.log('Email service initialized');
    } else {
      this.logger.warn('SMTP not configured. Email fallback disabled.');
    }
  }

  private getFrom(): string {
    const e = this.config.get('email', { infer: true });
    return e?.smtpFrom || 'noreply@servisgadget.com';
  }

  async send(to: string, subject: string, text: string): Promise<boolean> {
    if (!this.transporter) return false;
    try {
      await this.transporter.sendMail({ from: this.getFrom(), to, subject, text });
      return true;
    } catch (err) {
      this.logger.error(`Email send failed to ${to}: ${(err as Error).message}`);
      return false;
    }
  }
}
