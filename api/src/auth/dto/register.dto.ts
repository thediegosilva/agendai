import { ApiProperty } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import {
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'Maria Silva' })
  @IsString()
  @MinLength(2)
  name!: string;

  @ApiProperty({ example: 'maria@email.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'senhaForte123', minLength: 8 })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({ example: '11999998888', required: false })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({ enum: Role, default: Role.CLIENT, required: false })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;
}
