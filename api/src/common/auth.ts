import {
  CanActivate,
  createParamDecorator,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
  UseGuards,
  applyDecorators,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { ApiBearerAuth } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { PublicUser } from '../auth/auth.service';

/** Injeta o usuário autenticado (vindo do JwtStrategy). */
export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): PublicUser =>
    ctx.switchToHttp().getRequest().user,
);

const ROLES_KEY = 'roles';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<Role[] | undefined>(
      ROLES_KEY,
      [ctx.getHandler(), ctx.getClass()],
    );
    if (!roles?.length) return true;
    const user: PublicUser | undefined = ctx.switchToHttp().getRequest().user;
    if (!user || !roles.includes(user.role)) {
      throw new ForbiddenException('Ação não permitida para este perfil');
    }
    return true;
  }
}

/**
 * Exige JWT válido e, opcionalmente, um dos perfis informados.
 * Ex.: `@Auth()` (qualquer usuário logado) ou `@Auth(Role.OWNER)`.
 */
export function Auth(...roles: Role[]) {
  return applyDecorators(
    SetMetadata(ROLES_KEY, roles),
    UseGuards(AuthGuard('jwt'), RolesGuard),
    ApiBearerAuth(),
  );
}
