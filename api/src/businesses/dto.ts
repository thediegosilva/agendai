import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CreateBusinessDto {
  @ApiProperty({ example: 'Barbearia do Zé' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @ApiPropertyOptional({ example: 'Cortes clássicos e modernos.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ example: 'Rua das Flores, 123 - Centro' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  address?: string;
}

export class UpdateBusinessDto extends PartialType(CreateBusinessDto) {}

export class CreateServiceDto {
  @ApiProperty({ example: 'Corte masculino' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @ApiProperty({ example: 30, description: 'Duração em minutos' })
  @IsInt()
  @Min(5)
  @Max(8 * 60)
  durationMinutes!: number;

  @ApiProperty({ example: 4500, description: 'Preço em centavos' })
  @IsInt()
  @Min(0)
  @Max(10_000_000)
  priceCents!: number;
}

export class UpdateServiceDto extends PartialType(CreateServiceDto) {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class DayHoursDto {
  @ApiProperty({ example: 1, description: '0 = domingo ... 6 = sábado' })
  @IsInt()
  @Min(0)
  @Max(6)
  weekday!: number;

  @ApiProperty({ example: 540, description: 'Abertura em minutos (9h = 540)' })
  @IsInt()
  @Min(0)
  @Max(1439)
  openMinute!: number;

  @ApiProperty({ example: 1080, description: 'Fechamento (18h = 1080)' })
  @IsInt()
  @Min(1)
  @Max(1440)
  closeMinute!: number;
}

export class SetHoursDto {
  @ApiProperty({
    type: [DayHoursDto],
    description: 'Dias que abre. Dias ausentes ficam fechados.',
  })
  @ValidateNested({ each: true })
  @ArrayMaxSize(7)
  @Type(() => DayHoursDto)
  days!: DayHoursDto[];
}

export class AvailabilityQueryDto {
  @ApiProperty()
  @IsUUID()
  serviceId!: string;

  @ApiProperty({ example: '2026-11-20', description: 'Dia (YYYY-MM-DD)' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'date deve ser YYYY-MM-DD' })
  date!: string;
}

export class SearchQueryDto {
  @ApiPropertyOptional({ description: 'Busca pelo nome' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  q?: string;
}
