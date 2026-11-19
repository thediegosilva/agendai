import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export type PublicUser = Omit<User, 'passwordHash'>;

export function toPublicUser(user: User): PublicUser {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { passwordHash, ...rest } = user;
  return rest;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase().trim();
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new ConflictException('E-mail já cadastrado');

    const user = await this.prisma.user.create({
      data: {
        name: dto.name.trim(),
        email,
        phone: dto.phone,
        role: dto.role,
        passwordHash: await bcrypt.hash(dto.password, 10),
      },
    });
    return this.buildSession(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase().trim() },
    });
    const valid =
      user && (await bcrypt.compare(dto.password, user.passwordHash));
    if (!user || !valid)
      throw new UnauthorizedException('Credenciais inválidas');
    return this.buildSession(user);
  }

  private async buildSession(user: User) {
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      role: user.role,
    });
    return { accessToken, user: toPublicUser(user) };
  }
}
